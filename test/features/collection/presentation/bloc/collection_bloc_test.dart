// test/features/collection/presentation/bloc/collection_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/domain/entity/collection.dart';
import 'package:doormer/src/features/collection/domain/entity/deck.dart';
import 'package:doormer/src/features/collection/domain/entity/draw_outcome.dart';
import 'package:doormer/src/features/collection/domain/entity/holding.dart';
import 'package:doormer/src/features/collection/domain/repository/collection_repository.dart';
import 'package:doormer/src/features/collection/domain/usecase/convert_copy_usecase.dart';
import 'package:doormer/src/features/collection/domain/usecase/draw_card_usecase.dart';
import 'package:doormer/src/features/collection/domain/usecase/load_collection_usecase.dart';
import 'package:doormer/src/features/collection/presentation/bloc/collection_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const _gnomon = CollectibleCard(
  id: 'gnomon',
  name: 'Gnomon',
  deckId: 'meridian',
  rarity: Rarity.common,
  scaleLabel: 'Small',
  artAsset: 'a.png',
  description: 'd',
);

Collection _collection({int wallet = 120}) => Collection(
      decks: const [
        Deck(id: 'meridian', name: 'Meridian', cards: [_gnomon])
      ],
      holdingsByCardId: const {
        'gnomon': Holding(
          card: _gnomon,
          standardCopies: 1,
          specialCopies: 0,
        ),
      },
      walletPoints: wallet,
      drawCost: 40,
    );

class _FakeRepository implements CollectionRepository {
  bool failDraw = false;
  int drawCalls = 0;

  @override
  Future<Collection> load() async => _collection();

  int _wallet = 120;

  @override
  Future<Collection> current() async => _collection(wallet: _wallet);

  @override
  Future<DrawOutcome> draw(String deckId) async {
    drawCalls++;
    if (failDraw) throw ValidationFailure('Not enough points for a draw.');
    _wallet -= 40;
    return const DrawOutcome(
      card: _gnomon,
      variant: CardVariant.standard,
      kind: DrawResultKind.duplicate,
      copiesAfter: 2,
    );
  }

  @override
  Future<Collection> convertCopy(String cardId, CardVariant variant) async =>
      _collection(wallet: 125);
}

void main() {
  late _FakeRepository repository;
  CollectionBloc build() => CollectionBloc(
        loadCollection: LoadCollectionUseCase(repository),
        drawCard: DrawCardUseCase(repository),
        convertCopy: ConvertCopyUseCase(repository),
      );

  setUp(() => repository = _FakeRepository());

  blocTest<CollectionBloc, CollectionState>(
    'loads and selects no deck, so the list is the landing screen',
    build: build,
    act: (bloc) => bloc.add(const CollectionStarted()),
    expect: () => [
      isA<CollectionLoading>(),
      isA<CollectionReady>()
          .having((s) => s.selectedDeckId, 'selectedDeckId', isNull),
    ],
  );

  blocTest<CollectionBloc, CollectionState>(
    'selecting a deck keeps the collection and sets the deck',
    build: build,
    seed: () => CollectionReady(collection: _collection()),
    act: (bloc) => bloc.add(const DeckSelected('meridian')),
    expect: () => [
      isA<CollectionReady>()
          .having((s) => s.selectedDeckId, 'selectedDeckId', 'meridian'),
    ],
  );

  blocTest<CollectionBloc, CollectionState>(
    'a draw goes through drawing, then holds the outcome for the reveal',
    build: build,
    seed: () =>
        CollectionReady(collection: _collection(), selectedDeckId: 'meridian'),
    act: (bloc) => bloc.add(const DrawRequested()),
    expect: () => [
      isA<CollectionReady>().having((s) => s.isDrawing, 'isDrawing', isTrue),
      isA<CollectionReady>()
          .having((s) => s.isDrawing, 'isDrawing', isFalse)
          .having((s) => s.pendingReveal?.kind, 'reveal kind',
              DrawResultKind.duplicate),
    ],
  );

  blocTest<CollectionBloc, CollectionState>(
    'a new draw clears the previous reveal before it starts',
    build: build,
    seed: () => CollectionReady(
      collection: _collection(),
      selectedDeckId: 'meridian',
      pendingReveal: const DrawOutcome(
        card: _gnomon,
        variant: CardVariant.standard,
        kind: DrawResultKind.newCard,
        copiesAfter: 1,
      ),
    ),
    act: (bloc) => bloc.add(const DrawRequested()),
    expect: () => [
      isA<CollectionReady>()
          .having((s) => s.isDrawing, 'isDrawing', isTrue)
          .having((s) => s.pendingReveal, 'pendingReveal', isNull),
      isA<CollectionReady>()
          .having((s) => s.isDrawing, 'isDrawing', isFalse)
          .having((s) => s.pendingReveal?.kind, 'reveal kind',
              DrawResultKind.duplicate),
    ],
  );

  blocTest<CollectionBloc, CollectionState>(
    'closing the deck mid-draw is not undone when the draw lands',
    build: build,
    seed: () => CollectionReady(
      collection: _collection(),
      selectedDeckId: 'meridian',
    ),
    act: (bloc) async {
      bloc.add(const DrawRequested());
      bloc.add(const DeckClosed());
    },
    // The draw still lands and still pays out, but it must not reopen the deck.
    verify: (bloc) {
      final state = bloc.state as CollectionReady;
      expect(state.selectedDeckId, isNull,
          reason:
              'the student left the deck; the draw must not drag them back');
      expect(state.isDrawing, isFalse);
    },
  );

  blocTest<CollectionBloc, CollectionState>(
    'a draw refreshes the collection, so the wallet is never stale',
    build: build,
    seed: () => CollectionReady(
      collection: _collection(wallet: 120),
      selectedDeckId: 'meridian',
    ),
    act: (bloc) => bloc.add(const DrawRequested()),
    skip: 1,
    expect: () => [
      isA<CollectionReady>().having(
        (s) => s.collection.walletPoints,
        'walletPoints',
        80,
        // The repository spent the points; emitting the seeded collection here
        // would show 120 and the card just drawn would be missing.
      ),
    ],
  );

  blocTest<CollectionBloc, CollectionState>(
    'dismissing the reveal clears it without reloading',
    build: build,
    seed: () => CollectionReady(
      collection: _collection(),
      selectedDeckId: 'meridian',
      pendingReveal: const DrawOutcome(
        card: _gnomon,
        variant: CardVariant.standard,
        kind: DrawResultKind.newCard,
        copiesAfter: 1,
      ),
    ),
    act: (bloc) => bloc.add(const RevealDismissed()),
    expect: () => [
      isA<CollectionReady>()
          .having((s) => s.pendingReveal, 'pendingReveal', isNull),
    ],
  );

  blocTest<CollectionBloc, CollectionState>(
    'a failed draw reports the message and leaves the collection intact',
    build: () {
      repository.failDraw = true;
      return build();
    },
    seed: () =>
        CollectionReady(collection: _collection(), selectedDeckId: 'meridian'),
    act: (bloc) => bloc.add(const DrawRequested()),
    expect: () => [
      isA<CollectionReady>().having((s) => s.isDrawing, 'isDrawing', isTrue),
      isA<CollectionReady>()
          .having((s) => s.isDrawing, 'isDrawing', isFalse)
          .having((s) => s.pendingReveal, 'pendingReveal', isNull)
          .having((s) => s.errorMessage, 'errorMessage',
              'Not enough points for a draw.'),
    ],
  );

  blocTest<CollectionBloc, CollectionState>(
    'a draw is never issued while one is already running',
    build: build,
    seed: () => CollectionReady(
      collection: _collection(),
      selectedDeckId: 'meridian',
      isDrawing: true,
    ),
    act: (bloc) => bloc.add(const DrawRequested()),
    expect: () => const <CollectionState>[],
    verify: (_) => expect(repository.drawCalls, 0),
  );
}
