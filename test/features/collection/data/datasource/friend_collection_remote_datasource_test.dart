import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/collection/data/datasource/friend_collection_remote_datasource.dart';
import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request with one scripted reply, and keeps the last request.
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

FriendCollectionRemoteDataSource _dataSource(_FakeAdapter adapter) =>
    FriendCollectionRemoteDataSourceImpl(
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
    );

const _sam = {'friend_id': '42', 'nickname': 'Sam'};

const _decksReply = {
  'friend': _sam,
  'decks': [
    {
      'deck_id': 'meridian-01',
      'name': 'Meridian',
      'draw_cost': 40,
      'cards_total': 6,
      'cards_held': 3,
    },
  ],
};

const _cardsReply = {
  'friend': _sam,
  'deck': {'deck_id': 'meridian-01', 'name': 'Meridian'},
  'cards': [
    {
      'card_id': 'gnomon',
      'name': 'Gnomon',
      'rarity': 'common',
      'art_url': 'https://example.test/gnomon.png',
      'attributes': {'scale_label': 'Small', 'description': 'Casts a shadow.'},
      'standard_copies': 2,
      'special_copies': 1,
    },
    {
      'card_id': 'orrery',
      'name': 'The Orrery',
      'rarity': 'rare',
      'art_url': 'https://example.test/orrery.png',
      'attributes': null,
      'standard_copies': 0,
      'special_copies': 0,
    },
  ],
};

Matcher _throws<T extends Failure>(String message) =>
    throwsA(isA<T>().having((f) => f.message, 'message', message));

Matcher _refused(int status, String message) => throwsA(isA<RefusedFailure>()
    .having((f) => f.statusCode, 'statusCode', status)
    .having((f) => f.message, 'message', message));

void main() {
  setUpAll(AppLogger.disable);

  group('decks', () {
    test("posts the friend's id, and reads the friend and their decks",
        () async {
      final adapter = _FakeAdapter(body: _decksReply);

      final reply = await _dataSource(adapter).decks('42');

      expect(adapter.request!.method, 'POST');
      expect(adapter.request!.path, '/v1/friends/decks');
      expect(adapter.request!.data, {'friend_id': '42'});
      expect(reply.friend.nickname, 'Sam');
      expect(reply.decks.single.name, 'Meridian');
      expect(reply.decks.single.cardsHeld, 3);
    });
  });

  group('cards', () {
    test("posts the friend's and the deck's ids, and reads every card",
        () async {
      final adapter = _FakeAdapter(body: _cardsReply);

      final reply = await _dataSource(adapter).cards('42', 'meridian-01');
      final collection = reply.toEntity();

      expect(adapter.request!.path, '/v1/friends/cards');
      expect(
          adapter.request!.data, {'friend_id': '42', 'deck_id': 'meridian-01'});
      expect(reply.friend.friendId, '42');
      expect(collection.deck.name, 'Meridian');
      expect(collection.deck.size, 2);
      expect(collection.holdings.single.card.rarity, Rarity.common);
      expect(collection.holdings.single.specialCopies, 1);
      expect(collection.holdings.single.card.scaleLabel, 'Small');
    });

    test('a card with no copies has no holding', () async {
      final reply =
          await _dataSource(_FakeAdapter(body: _cardsReply)).cards('42', 'x');

      expect(reply.toEntity().holdingOf('orrery'), isNull);
    });
  });

  group('words for each status the API refuses with', () {
    for (final (status, message) in [
      (403, 'Friends is turned off for your account.'),
      (404, "We couldn't find that friend."),
      (429, "You've done that a lot today. Try again tomorrow."),
    ]) {
      test('$status says "$message"', () async {
        final friends =
            _dataSource(_FakeAdapter(status: status, body: 'not friends'));

        await expectLater(friends.decks('42'), _refused(status, message));
        await expectLater(
            friends.cards('42', 'meridian-01'), _refused(status, message));
      });
    }
  });

  test("anything else says the friend's cards couldn't load", () async {
    await expectLater(
      _dataSource(_FakeAdapter(status: 500, body: 'boom')).decks('42'),
      _throws<ServerFailure>("We couldn't load your friend's cards."),
    );
    await expectLater(
      _dataSource(_FakeAdapter(throws: DioExceptionType.connectionError))
          .cards('42', 'meridian-01'),
      _throws<NetworkFailure>("We couldn't load your friend's cards."),
    );
  });

  test('an answer it cannot read is an unknown failure', () async {
    await expectLater(
      _dataSource(_FakeAdapter(body: {'decks': 'nope'})).decks('42'),
      _throws<UnknownFailure>("We couldn't load your friend's cards."),
    );
  });
}
