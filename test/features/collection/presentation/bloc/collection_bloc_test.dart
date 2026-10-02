// test/features/collection/presentation/bloc/collection_bloc_test.dart
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/domain/entity/collection.dart';
import 'package:doormer/src/features/collection/domain/entity/deck.dart';
import 'package:doormer/src/features/collection/domain/entity/deck_progress.dart';
import 'package:doormer/src/features/collection/domain/entity/draw_outcome.dart';
import 'package:doormer/src/features/collection/domain/entity/holding.dart';
import 'package:doormer/src/features/collection/domain/repository/collection_repository.dart';
import 'package:doormer/src/features/collection/domain/usecase/draw_card_usecase.dart';
import 'package:doormer/src/features/collection/domain/usecase/load_collection_usecase.dart';
import 'package:doormer/src/features/collection/domain/usecase/load_decks_usecase.dart';
import 'package:doormer/src/features/collection/domain/usecase/shatter_copy_usecase.dart';
import 'package:doormer/src/features/collection/presentation/bloc/collection_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

CollectibleCard _card(String id) => CollectibleCard(
      id: id,
      name: id,
      rarity: Rarity.common,
      scaleLabel: 'Small',
      artUrl: 'https://example.test/$id.jpg',
      standardShatterQuarks: 5,
      specialShatterQuarks: 10,
      description: 'd',
    );

final _decks = {
  'meridian': Deck(
    id: 'meridian',
    name: 'Meridian',
    drawCost: 40,
    cards: [_card('gnomon'), _card('vernier')],
  ),
  'cinder': Deck(
    id: 'cinder',
    name: 'Cinder',
    drawCost: 40,
    cards: [_card('flint')],
  ),
};

/// Plays the server: it holds the balance and what is held, and each draw
/// takes the deck's first card. A test can make a kind of call fail, or hold
/// it open until the test lets it answer.
class _FakeRepository implements CollectionRepository {
  int quarkBalance = 120;
  final Map<String, Map<String, Holding>> holdings = {
    'meridian': {
      'gnomon': Holding(
        card: _decks['meridian']!.cards.first,
        standardCopies: 2,
        specialCopies: 0,
      ),
    },
    'cinder': {},
  };

  Object? decksError;
  final Map<String, Object> cardsErrors = {};
  Object? drawError;
  Object? shatterError;

  final Map<String, Completer<void>> heldReads = {};
  Completer<void>? heldDraw;
  Completer<void>? heldShatter;

  int decksCalls = 0;
  int drawCalls = 0;
  int shatterCalls = 0;

  /// What the collection opens on. A test sets it to play an earlier visit.
  @override
  ({int quarkBalance, List<DeckProgress> decks})? lastDeckList;

  @override
  void forgetLastDeckList() {
    lastDeckList = null;
  }

  Collection collectionOf(String deckId) => Collection(
        deck: _decks[deckId]!,
        holdingsByCardId: Map.of(holdings[deckId]!),
      );

  List<DeckProgress> get deckList => [
        for (final deck in _decks.values)
          DeckProgress(
            deckId: deck.id,
            name: deck.name,
            cardsHeld: holdings[deck.id]!.length,
            cardsTotal: deck.size,
          ),
      ];

  static void _throwIfSet(Object? error) {
    if (error != null) throw error;
  }

  @override
  Future<({int quarkBalance, List<DeckProgress> decks})> loadDecks() async {
    decksCalls++;
    _throwIfSet(decksError);
    return (quarkBalance: quarkBalance, decks: deckList);
  }

  @override
  Future<({int quarkBalance, Collection collection})> loadCollection(
    String deckId,
  ) async {
    await heldReads[deckId]?.future;
    _throwIfSet(cardsErrors[deckId]);
    return (quarkBalance: quarkBalance, collection: collectionOf(deckId));
  }

  @override
  Future<({int quarkBalance, DrawOutcome outcome})> draw(String deckId) async {
    drawCalls++;
    await heldDraw?.future;
    _throwIfSet(drawError);
    final card = _decks[deckId]!.cards.first;
    final before = holdings[deckId]![card.id];
    final after = Holding(
      card: card,
      standardCopies: (before?.standardCopies ?? 0) + 1,
      specialCopies: before?.specialCopies ?? 0,
    );
    holdings[deckId]![card.id] = after;
    quarkBalance -= _decks[deckId]!.drawCost;
    return (
      quarkBalance: quarkBalance,
      outcome: DrawOutcome(
        card: card,
        variant: CardVariant.standard,
        result: before == null ? DrawResult.newCard : DrawResult.duplicate,
        copiesAfter: after.totalCopies,
      ),
    );
  }

  @override
  Future<({int quarkBalance, int standardCopies, int specialCopies})>
      shatterCopy(String deckId, String cardId, CardVariant variant) async {
    shatterCalls++;
    await heldShatter?.future;
    _throwIfSet(shatterError);
    final before = holdings[deckId]![cardId]!;
    final after = Holding(
      card: before.card,
      standardCopies:
          before.standardCopies - (variant == CardVariant.standard ? 1 : 0),
      specialCopies:
          before.specialCopies - (variant == CardVariant.special ? 1 : 0),
    );
    holdings[deckId]![cardId] = after;
    quarkBalance += before.card.shatterQuarksFor(variant);
    return (
      quarkBalance: quarkBalance,
      standardCopies: after.standardCopies,
      specialCopies: after.specialCopies,
    );
  }
}

/// Lets every answer that is not held open arrive.
Future<void> _answersArrive() => Future<void>.delayed(Duration.zero);

void main() {
  setUpAll(AppLogger.disable);

  late _FakeRepository repository;
  CollectionBloc build() => CollectionBloc(
        loadDecks: LoadDecksUseCase(repository),
        loadCollection: LoadCollectionUseCase(repository),
        drawCard: DrawCardUseCase(repository),
        shatterCopy: ShatterCopyUseCase(repository),
      );

  CollectionReady deckList() => CollectionReady(
        quarkBalance: repository.quarkBalance,
        decks: repository.deckList,
      );

  CollectionReady meridianOpen({
    bool isDrawing = false,
    bool isShattering = false,
  }) =>
      CollectionReady(
        quarkBalance: repository.quarkBalance,
        decks: repository.deckList,
        selectedDeckId: 'meridian',
        collection: repository.collectionOf('meridian'),
        isDrawing: isDrawing,
        isShattering: isShattering,
      );

  setUp(() => repository = _FakeRepository());

  group('starting', () {
    blocTest<CollectionBloc, CollectionState>(
      'loads the deck list and opens no deck, so the list is the home',
      build: build,
      act: (bloc) => bloc.add(const CollectionStarted()),
      expect: () => [
        isA<CollectionLoading>(),
        isA<CollectionReady>()
            .having((s) => s.quarkBalance, 'quarkBalance', 120)
            .having((s) => s.decks.length, 'decks', 2)
            .having((s) => s.selectedDeckId, 'selectedDeckId', isNull),
      ],
    );

    blocTest<CollectionBloc, CollectionState>(
      'a failed first read is the page error',
      build: () {
        repository.decksError = NetworkFailure(
            "We couldn't connect. Check your connection and try again.");
        return build();
      },
      act: (bloc) => bloc.add(const CollectionStarted()),
      expect: () => [
        isA<CollectionLoading>(),
        const CollectionError(
            "We couldn't connect. Check your connection and try again."),
      ],
    );

    blocTest<CollectionBloc, CollectionState>(
      'an error that is not a failure is reported plainly',
      build: () {
        repository.decksError = StateError('a bug');
        return build();
      },
      act: (bloc) => bloc.add(const CollectionStarted()),
      expect: () => [
        isA<CollectionLoading>(),
        const CollectionError('Something went wrong. Try again.'),
      ],
    );
  });

  group('opening a deck', () {
    blocTest<CollectionBloc, CollectionState>(
      'shows it loading, then shows it and a fresh deck list',
      build: build,
      seed: deckList,
      act: (bloc) {
        // Changed on the server since the list was read.
        repository.quarkBalance = 95;
        bloc.add(const DeckSelected('meridian'));
      },
      expect: () => [
        isA<CollectionReady>()
            .having((s) => s.selectedDeckId, 'selectedDeckId', 'meridian')
            .having((s) => s.collection, 'collection', isNull),
        isA<CollectionReady>()
            .having((s) => s.collection?.deck.id, 'collection', 'meridian')
            .having((s) => s.quarkBalance, 'quarkBalance', 95),
      ],
    );

    blocTest<CollectionBloc, CollectionState>(
      'a failed read leaves the deck pane with the reason',
      build: () {
        repository.cardsErrors['meridian'] =
            ServerFailure('Something went wrong. Try again.');
        return build();
      },
      seed: deckList,
      act: (bloc) => bloc.add(const DeckSelected('meridian')),
      expect: () => [
        isA<CollectionReady>()
            .having((s) => s.collection, 'collection', isNull),
        isA<CollectionReady>()
            .having((s) => s.collection, 'collection', isNull)
            .having((s) => s.deckErrorMessage, 'deckErrorMessage',
                'Something went wrong. Try again.'),
      ],
    );

    blocTest<CollectionBloc, CollectionState>(
      'if the deck list fails after the deck read, nothing partial is shown',
      build: () {
        repository.decksError =
            ServerFailure('Something went wrong. Try again.');
        return build();
      },
      seed: deckList,
      act: (bloc) => bloc.add(const DeckSelected('meridian')),
      verify: (bloc) {
        final state = bloc.state as CollectionReady;
        expect(state.collection, isNull,
            reason: 'a grid beside a stale list is never shown');
        expect(state.deckErrorMessage, 'Something went wrong. Try again.');
      },
    );

    blocTest<CollectionBloc, CollectionState>(
      'opening it again after a failed read clears the reason and reads again',
      build: build,
      seed: () => CollectionReady(
        quarkBalance: 120,
        decks: repository.deckList,
        selectedDeckId: 'meridian',
        deckErrorMessage: 'Something went wrong. Try again.',
      ),
      act: (bloc) => bloc.add(const DeckSelected('meridian')),
      expect: () => [
        isA<CollectionReady>()
            .having((s) => s.deckErrorMessage, 'deckErrorMessage', isNull)
            .having((s) => s.collection, 'collection', isNull),
        isA<CollectionReady>()
            .having((s) => s.collection?.deck.id, 'collection', 'meridian'),
      ],
    );

    blocTest<CollectionBloc, CollectionState>(
      'a read that lands after another deck was opened does not replace it',
      build: build,
      seed: deckList,
      act: (bloc) async {
        repository.heldReads['meridian'] = Completer<void>();
        bloc.add(const DeckSelected('meridian'));
        await _answersArrive();
        bloc.add(const DeckSelected('cinder'));
        await _answersArrive();
        repository.quarkBalance = 95;
        repository.heldReads['meridian']!.complete();
        await _answersArrive();
      },
      verify: (bloc) {
        final state = bloc.state as CollectionReady;
        expect(state.selectedDeckId, 'cinder');
        expect(state.collection?.deck.id, 'cinder');
        expect(state.quarkBalance, 95,
            reason: 'the balance and the list are true whichever deck is open');
      },
    );

    blocTest<CollectionBloc, CollectionState>(
      'a read that fails after another deck was opened leaves that deck alone',
      build: build,
      seed: deckList,
      act: (bloc) async {
        repository.heldReads['meridian'] = Completer<void>();
        repository.cardsErrors['meridian'] =
            ServerFailure('Something went wrong. Try again.');
        bloc.add(const DeckSelected('meridian'));
        await _answersArrive();
        bloc.add(const DeckSelected('cinder'));
        await _answersArrive();
        repository.heldReads['meridian']!.complete();
        await _answersArrive();
      },
      verify: (bloc) {
        final state = bloc.state as CollectionReady;
        expect(state.collection?.deck.id, 'cinder');
        expect(state.deckErrorMessage, isNull);
      },
    );

    blocTest<CollectionBloc, CollectionState>(
      'closing the deck clears it and any reason it failed',
      build: build,
      seed: () => CollectionReady(
        quarkBalance: 120,
        decks: repository.deckList,
        selectedDeckId: 'meridian',
        deckErrorMessage: 'Something went wrong. Try again.',
      ),
      act: (bloc) => bloc.add(const DeckClosed()),
      expect: () => [
        isA<CollectionReady>()
            .having((s) => s.selectedDeckId, 'selectedDeckId', isNull)
            .having((s) => s.collection, 'collection', isNull)
            .having((s) => s.deckErrorMessage, 'deckErrorMessage', isNull),
      ],
    );
  });

  group('drawing', () {
    blocTest<CollectionBloc, CollectionState>(
      'reads the deck again before the reveal, so nothing shown is stale',
      build: build,
      seed: meridianOpen,
      act: (bloc) => bloc.add(const DrawRequested()),
      expect: () => [
        isA<CollectionReady>().having((s) => s.isDrawing, 'isDrawing', isTrue),
        isA<CollectionReady>()
            .having((s) => s.isDrawing, 'isDrawing', isFalse)
            .having((s) => s.quarkBalance, 'quarkBalance', 80)
            .having((s) => s.collection?.holdingOf('gnomon')?.totalCopies,
                'gnomon copies', 3)
            .having((s) => s.pendingReveal?.outcome.result, 'reveal',
                DrawResult.duplicate)
            .having((s) => s.pendingReveal?.deckName, 'deckName', 'Meridian')
            .having(
                (s) => s.pendingReveal?.collectionAfterDraw
                    ?.holdingOf('gnomon')
                    ?.totalCopies,
                'collection after the draw',
                3),
      ],
    );

    blocTest<CollectionBloc, CollectionState>(
      'a new draw clears the previous reveal before it starts',
      build: build,
      seed: () => meridianOpen().copyWith(
        pendingReveal: PendingReveal(
          outcome: DrawOutcome(
            card: _card('gnomon'),
            variant: CardVariant.standard,
            result: DrawResult.newCard,
            copiesAfter: 1,
          ),
          deckName: 'Meridian',
        ),
      ),
      act: (bloc) => bloc.add(const DrawRequested()),
      expect: () => [
        isA<CollectionReady>()
            .having((s) => s.isDrawing, 'isDrawing', isTrue)
            .having((s) => s.pendingReveal, 'pendingReveal', isNull),
        isA<CollectionReady>().having((s) => s.pendingReveal?.outcome.result,
            'reveal', DrawResult.duplicate),
      ],
    );

    blocTest<CollectionBloc, CollectionState>(
      'is ignored until the open deck has loaded',
      build: build,
      seed: () => deckList().copyWith(selectedDeckId: 'meridian'),
      act: (bloc) => bloc.add(const DrawRequested()),
      expect: () => const <CollectionState>[],
      verify: (_) => expect(repository.drawCalls, 0),
    );

    blocTest<CollectionBloc, CollectionState>(
      'is ignored while a draw is in flight, so a second tap cannot spend twice',
      build: build,
      seed: () => meridianOpen(isDrawing: true),
      act: (bloc) => bloc.add(const DrawRequested()),
      expect: () => const <CollectionState>[],
      verify: (_) => expect(repository.drawCalls, 0),
    );

    blocTest<CollectionBloc, CollectionState>(
      'is ignored while a shatter is in flight',
      build: build,
      seed: () => meridianOpen(isShattering: true),
      act: (bloc) => bloc.add(const DrawRequested()),
      expect: () => const <CollectionState>[],
      verify: (_) => expect(repository.drawCalls, 0),
    );

    blocTest<CollectionBloc, CollectionState>(
      'a refused draw raises the toast and plays no reveal',
      build: () {
        repository.drawError =
            ValidationFailure("You don't have enough quarks for a draw.");
        return build();
      },
      seed: meridianOpen,
      act: (bloc) => bloc.add(const DrawRequested()),
      expect: () => [
        isA<CollectionReady>().having((s) => s.isDrawing, 'isDrawing', isTrue),
        isA<CollectionReady>()
            .having((s) => s.isDrawing, 'isDrawing', isFalse)
            .having((s) => s.pendingReveal, 'pendingReveal', isNull)
            .having((s) => s.errorMessage, 'errorMessage',
                "You don't have enough quarks for a draw."),
      ],
    );

    blocTest<CollectionBloc, CollectionState>(
      'a draw whose read fails still plays the reveal, with the draw balance',
      build: build,
      seed: meridianOpen,
      act: (bloc) {
        // The draw goes through; the reads after it do not.
        repository.cardsErrors['meridian'] = NetworkFailure(
            "We couldn't connect. Check your connection and try again.");
        bloc.add(const DrawRequested());
      },
      expect: () => [
        isA<CollectionReady>().having((s) => s.isDrawing, 'isDrawing', isTrue),
        isA<CollectionReady>()
            .having((s) => s.isDrawing, 'isDrawing', isFalse)
            .having((s) => s.quarkBalance, 'quarkBalance', 80)
            .having((s) => s.pendingReveal?.outcome.result, 'reveal',
                DrawResult.duplicate)
            .having((s) => s.pendingReveal?.collectionAfterDraw,
                'collection after the draw', isNull)
            .having((s) => s.collection, 'collection', isNull)
            .having((s) => s.deckErrorMessage, 'deckErrorMessage',
                "We couldn't connect. Check your connection and try again."),
      ],
    );

    blocTest<CollectionBloc, CollectionState>(
      'a draw on a deck the student has left still describes the drawn deck',
      build: build,
      seed: meridianOpen,
      act: (bloc) async {
        repository.heldDraw = Completer<void>();
        bloc.add(const DrawRequested());
        await _answersArrive();
        bloc.add(const DeckSelected('cinder'));
        await _answersArrive();
        repository.heldDraw!.complete();
        await _answersArrive();
      },
      verify: (bloc) {
        final state = bloc.state as CollectionReady;
        expect(state.selectedDeckId, 'cinder');
        expect(state.collection?.deck.id, 'cinder',
            reason: 'only the open deck is shown');
        expect(state.pendingReveal?.deckName, 'Meridian');
        expect(state.pendingReveal?.collectionAfterDraw?.deck.id, 'meridian');
        expect(state.quarkBalance, 80);
        expect(state.isDrawing, isFalse);
      },
    );

    blocTest<CollectionBloc, CollectionState>(
      'closing the deck mid-draw is not undone when the draw lands',
      build: build,
      seed: meridianOpen,
      act: (bloc) {
        bloc.add(const DrawRequested());
        bloc.add(const DeckClosed());
      },
      verify: (bloc) {
        final state = bloc.state as CollectionReady;
        expect(state.selectedDeckId, isNull,
            reason:
                'the student left the deck; the draw must not drag them back');
        expect(state.collection, isNull);
        expect(state.isDrawing, isFalse);
        expect(state.pendingReveal, isNotNull,
            reason: 'the card is paid for, so it is still revealed');
      },
    );

    blocTest<CollectionBloc, CollectionState>(
      'dismissing the reveal clears it without reading anything',
      build: build,
      seed: () => meridianOpen().copyWith(
        pendingReveal: PendingReveal(
          outcome: DrawOutcome(
            card: _card('gnomon'),
            variant: CardVariant.standard,
            result: DrawResult.newCard,
            copiesAfter: 1,
          ),
          deckName: 'Meridian',
        ),
      ),
      act: (bloc) => bloc.add(const RevealDismissed()),
      expect: () => [
        isA<CollectionReady>()
            .having((s) => s.pendingReveal, 'pendingReveal', isNull),
      ],
      verify: (_) => expect(repository.decksCalls, 0),
    );
  });

  group('shattering', () {
    blocTest<CollectionBloc, CollectionState>(
      'applies the balance and the copies left, without reading again',
      build: build,
      seed: meridianOpen,
      act: (bloc) =>
          bloc.add(const ShatterCopyRequested('gnomon', CardVariant.standard)),
      expect: () => [
        isA<CollectionReady>()
            .having((s) => s.isShattering, 'isShattering', isTrue),
        isA<CollectionReady>()
            .having((s) => s.isShattering, 'isShattering', isFalse)
            .having((s) => s.quarkBalance, 'quarkBalance', 125)
            .having((s) => s.collection?.holdingOf('gnomon')?.standardCopies,
                'gnomon copies', 1),
      ],
      verify: (_) => expect(repository.decksCalls, 0),
    );

    blocTest<CollectionBloc, CollectionState>(
      'is ignored while a draw is in flight',
      build: build,
      seed: () => meridianOpen(isDrawing: true),
      act: (bloc) =>
          bloc.add(const ShatterCopyRequested('gnomon', CardVariant.standard)),
      expect: () => const <CollectionState>[],
      verify: (_) => expect(repository.shatterCalls, 0),
    );

    blocTest<CollectionBloc, CollectionState>(
      'is ignored while another shatter is in flight',
      build: build,
      seed: () => meridianOpen(isShattering: true),
      act: (bloc) =>
          bloc.add(const ShatterCopyRequested('gnomon', CardVariant.standard)),
      expect: () => const <CollectionState>[],
      verify: (_) => expect(repository.shatterCalls, 0),
    );

    blocTest<CollectionBloc, CollectionState>(
      'a shatter that lands after the deck was left changes only the balance',
      build: build,
      seed: meridianOpen,
      act: (bloc) async {
        repository.heldShatter = Completer<void>();
        bloc.add(const ShatterCopyRequested('gnomon', CardVariant.standard));
        await _answersArrive();
        bloc.add(const DeckSelected('cinder'));
        await _answersArrive();
        repository.heldShatter!.complete();
        await _answersArrive();
      },
      verify: (bloc) {
        final state = bloc.state as CollectionReady;
        expect(state.collection?.deck.id, 'cinder');
        expect(state.quarkBalance, 125);
        expect(state.isShattering, isFalse);
        expect(state.errorMessage, isNull);
      },
    );

    blocTest<CollectionBloc, CollectionState>(
      'a refused shatter raises the toast and changes nothing',
      build: () {
        repository.shatterError =
            ValidationFailure("You don't have a spare copy of that card.");
        return build();
      },
      seed: meridianOpen,
      act: (bloc) =>
          bloc.add(const ShatterCopyRequested('gnomon', CardVariant.standard)),
      expect: () => [
        isA<CollectionReady>()
            .having((s) => s.isShattering, 'isShattering', isTrue),
        isA<CollectionReady>()
            .having((s) => s.isShattering, 'isShattering', isFalse)
            .having((s) => s.quarkBalance, 'quarkBalance', 120)
            .having((s) => s.errorMessage, 'errorMessage',
                "You don't have a spare copy of that card."),
      ],
    );
  });
}
