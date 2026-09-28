import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/collection/data/datasource/collection_remote_datasource.dart';
import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/draw_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request with one scripted reply, and keeps the last request.
///
/// A [body] that is a `String` is sent as plain text, as-is; anything else is
/// sent as JSON. When [throws] is set, the request fails with that kind of
/// error instead of being answered.
class _FakeAdapter implements HttpClientAdapter {
  final int status;
  final Object? body;
  final DioExceptionType? throws;
  RequestOptions? request;

  _FakeAdapter({this.status = 200, this.body = const {}, this.throws});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    final type = throws;
    if (type != null) throw DioException(requestOptions: options, type: type);
    final reply = body;
    if (reply is String) {
      return ResponseBody.fromString(reply, status, headers: {
        Headers.contentTypeHeader: ['text/plain'],
      });
    }
    return ResponseBody.fromString(jsonEncode(reply), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

CollectionRemoteDataSource _dataSource(_FakeAdapter adapter) =>
    CollectionRemoteDataSourceImpl(
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
    );

Map<String, dynamic> _heldCard({
  String cardId = 'gnomon',
  String rarity = 'common',
  Object? attributes = const {
    'description': 'Casts a shadow.',
    'scale_label': 'Small',
  },
  int standardCopies = 1,
  int specialCopies = 0,
}) =>
    {
      'card_id': cardId,
      'name': 'Gnomon',
      'rarity': rarity,
      'art_url': 'https://example.test/gnomon.jpg',
      'attributes': attributes,
      'standard_copies': standardCopies,
      'special_copies': specialCopies,
      'standard_shatter_quarks': 5,
      'special_shatter_quarks': 10,
    };

Map<String, dynamic> _drawReply({
  String variant = 'standard',
  String result = 'new_card',
  String rarity = 'common',
}) =>
    {
      'quark_balance': 0,
      'card': _heldCard(rarity: rarity, standardCopies: 0),
      'variant': variant,
      'result': result,
      'copies_after': 1,
    };

Matcher _throws<T extends Failure>(String message) =>
    throwsA(isA<T>().having((f) => f.message, 'message', message));

const _couldNotConnect =
    "We couldn't connect. Check your connection and try again.";
const _somethingWentWrong = 'Something went wrong. Try again.';

void main() {
  setUpAll(AppLogger.disable);

  group('decks', () {
    test('posts an empty body with no key, and reads every deck', () async {
      final adapter = _FakeAdapter(body: {
        'quark_balance': 40,
        'decks': [
          {
            'deck_id': 'meridian-01',
            'name': 'Meridian',
            'draw_cost': 40,
            'cards_total': 6,
            'cards_held': 4,
            'cards_with_special': 1,
            'rarity_mix': [],
          },
        ],
      });

      final reply = await _dataSource(adapter).decks();

      expect(adapter.request!.method, 'POST');
      expect(adapter.request!.path, '/v1/collection/decks');
      expect(adapter.request!.data, isEmpty);
      expect(adapter.request!.headers.containsKey('Idempotency-Key'), isFalse);
      expect(reply.quarkBalance, 40);
      expect(reply.decks.single.deckId, 'meridian-01');
      expect(reply.decks.single.name, 'Meridian');
      expect(reply.decks.single.cardsHeld, 4);
      expect(reply.decks.single.cardsTotal, 6);
    });
  });

  group('cards', () {
    test('posts the deck id, and reads the deck and every card in it',
        () async {
      final adapter = _FakeAdapter(body: {
        'quark_balance': 40,
        'deck': {'deck_id': 'meridian-01', 'name': 'Meridian', 'draw_cost': 40},
        'cards': [
          _heldCard(standardCopies: 2, specialCopies: 1),
          _heldCard(cardId: 'orrery', rarity: 'rare', standardCopies: 0),
        ],
      });

      final reply = await _dataSource(adapter).cards('meridian-01');

      expect(adapter.request!.path, '/v1/collection/cards');
      expect(adapter.request!.data, {'deck_id': 'meridian-01'});
      expect(reply.quarkBalance, 40);
      expect(reply.deck.deckId, 'meridian-01');
      expect(reply.deck.name, 'Meridian');
      expect(reply.deck.drawCost, 40);

      final gnomon = reply.cards.first;
      expect(gnomon.cardId, 'gnomon');
      expect(gnomon.name, 'Gnomon');
      expect(gnomon.rarity, Rarity.common);
      expect(gnomon.artUrl, 'https://example.test/gnomon.jpg');
      expect(gnomon.description, 'Casts a shadow.');
      expect(gnomon.scaleLabel, 'Small');
      expect(gnomon.standardCopies, 2);
      expect(gnomon.specialCopies, 1);
      expect(gnomon.standardShatterQuarks, 5);
      expect(gnomon.specialShatterQuarks, 10);

      final orrery = reply.cards.last;
      expect(orrery.rarity, Rarity.rare);
      expect(orrery.standardCopies + orrery.specialCopies, 0,
          reason: 'a card not held yet still comes back, with no copies');
    });

    test('a card with no attributes reads them as empty text', () async {
      final adapter = _FakeAdapter(body: {
        'quark_balance': 40,
        'deck': {'deck_id': 'cinder-01', 'name': 'Cinder', 'draw_cost': 40},
        'cards': [_heldCard(attributes: null)],
      });

      final card = (await _dataSource(adapter).cards('cinder-01')).cards.single;

      expect(card.description, '');
      expect(card.scaleLabel, '');
    });
  });

  group('draw', () {
    test('posts the deck id with the key, and reads the outcome', () async {
      final adapter =
          _FakeAdapter(body: _drawReply(variant: 'special', result: 'upgrade'));

      final reply = await _dataSource(adapter)
          .draw('meridian-01', idempotencyKey: 'key-1');

      expect(adapter.request!.path, '/v1/collection/draw');
      expect(adapter.request!.data, {'deck_id': 'meridian-01'});
      expect(adapter.request!.headers['Idempotency-Key'], 'key-1');
      expect(reply.quarkBalance, 0);
      expect(reply.card.cardId, 'gnomon');
      expect(reply.variant, CardVariant.special);
      expect(reply.result, DrawResult.upgrade);
      expect(reply.copiesAfter, 1);
    });

    test('reads every result the API sends', () async {
      const results = {
        'new_card': DrawResult.newCard,
        'upgrade': DrawResult.upgrade,
        'duplicate': DrawResult.duplicate,
      };
      for (final entry in results.entries) {
        final reply = await _dataSource(
          _FakeAdapter(body: _drawReply(result: entry.key)),
        ).draw('meridian-01', idempotencyKey: 'k');
        expect(reply.result, entry.value, reason: entry.key);
      }
    });
  });

  group('shatter', () {
    test('posts the deck, the card and the printing with the key', () async {
      final adapter = _FakeAdapter(body: {
        'quark_balance': 45,
        'quarks_gained': 5,
        'card_id': 'gnomon',
        'standard_copies': 1,
        'special_copies': 1,
      });

      final reply = await _dataSource(adapter).shatter(
        'meridian-01',
        'gnomon',
        CardVariant.standard,
        idempotencyKey: 'key-2',
      );

      expect(adapter.request!.path, '/v1/collection/shatter');
      expect(adapter.request!.data, {
        'deck_id': 'meridian-01',
        'card_id': 'gnomon',
        'variant': 'standard',
      });
      expect(adapter.request!.headers['Idempotency-Key'], 'key-2');
      expect(reply.quarkBalance, 45);
      expect(reply.standardCopies, 1);
      expect(reply.specialCopies, 1);
    });
  });

  group('failures carry the message a student sees', () {
    test('a refused draw', () async {
      final adapter = _FakeAdapter(status: 409, body: {'msg': 'server text'});
      await expectLater(
        _dataSource(adapter).draw('meridian-01', idempotencyKey: 'k'),
        _throws<ValidationFailure>("You don't have enough quarks for a draw."),
      );
    });

    test('a refused shatter', () async {
      final adapter = _FakeAdapter(status: 409, body: {'msg': 'server text'});
      await expectLater(
        _dataSource(adapter).shatter(
            'meridian-01', 'gnomon', CardVariant.standard,
            idempotencyKey: 'k'),
        _throws<ValidationFailure>("You don't have a spare copy of that card."),
      );
    });

    test('a 409 on a read is any other 4xx', () async {
      final adapter = _FakeAdapter(status: 409, body: {'msg': 'server text'});
      await expectLater(
        _dataSource(adapter).decks(),
        _throws<ApiFailure>('Error 409: $_somethingWentWrong'),
      );
    });

    test('a timeout or no connection', () async {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        await expectLater(
          _dataSource(_FakeAdapter(throws: type))
              .draw('meridian-01', idempotencyKey: 'k'),
          _throws<NetworkFailure>(_couldNotConnect),
          reason: type.name,
        );
      }
    });

    test('a server error', () async {
      final adapter = _FakeAdapter(status: 503, body: {'msg': 'server text'});
      await expectLater(
        _dataSource(adapter).draw('meridian-01', idempotencyKey: 'k'),
        _throws<ServerFailure>(_somethingWentWrong),
      );
    });

    test('signed out', () async {
      final adapter = _FakeAdapter(status: 401, body: {'msg': 'server text'});
      await expectLater(
        _dataSource(adapter).decks(),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('any other 4xx', () async {
      final adapter = _FakeAdapter(status: 404, body: {'msg': 'server text'});
      await expectLater(
        _dataSource(adapter).cards('no-such-deck'),
        _throws<ApiFailure>('Error 404: $_somethingWentWrong'),
      );
    });

    test('a response that is not JSON', () async {
      final adapter = _FakeAdapter(body: 'not json');
      await expectLater(
        _dataSource(adapter).decks(),
        _throws<UnknownFailure>(_somethingWentWrong),
      );
    });

    test('a response with a field missing', () async {
      final adapter = _FakeAdapter(body: {'decks': []});
      await expectLater(
        _dataSource(adapter).decks(),
        _throws<UnknownFailure>(_somethingWentWrong),
      );
    });

    test('a rarity, printing or result the app does not know', () async {
      for (final reply in [
        _drawReply(rarity: 'legendary'),
        _drawReply(variant: 'holo'),
        _drawReply(result: 'jackpot'),
      ]) {
        await expectLater(
          _dataSource(_FakeAdapter(body: reply))
              .draw('meridian-01', idempotencyKey: 'k'),
          _throws<UnknownFailure>(_somethingWentWrong),
        );
      }
    });
  });
}
