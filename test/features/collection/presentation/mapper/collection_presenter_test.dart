import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/domain/entity/collection.dart';
import 'package:doormer/src/features/collection/domain/entity/deck.dart';
import 'package:doormer/src/features/collection/domain/entity/deck_progress.dart';
import 'package:doormer/src/features/collection/domain/entity/draw_outcome.dart';
import 'package:doormer/src/features/collection/domain/entity/holding.dart';
import 'package:doormer/src/features/collection/presentation/mapper/collection_presenter.dart';
import 'package:flutter_test/flutter_test.dart';

const _gnomon = CollectibleCard(
  id: 'gnomon',
  name: 'Gnomon',
  rarity: Rarity.common,
  scaleLabel: 'Small',
  artUrl: 'https://example.test/gnomon.jpg',
  standardShatterQuarks: 5,
  specialShatterQuarks: 10,
  description: 'd',
);
const _vernier = CollectibleCard(
  id: 'vernier',
  name: 'Vernier',
  rarity: Rarity.common,
  scaleLabel: 'Small',
  artUrl: 'https://example.test/vernier.jpg',
  standardShatterQuarks: 5,
  specialShatterQuarks: 10,
  description: 'd',
);
const _deck = Deck(
  id: 'meridian',
  name: 'Meridian',
  drawCost: 40,
  cards: [_gnomon, _vernier],
);

DrawOutcome _outcome(DrawResult result) => DrawOutcome(
      card: _gnomon,
      variant: CardVariant.standard,
      result: result,
      copiesAfter: 2,
    );

Collection _collectionWithGnomon(
        {required int standard, required int special}) =>
    Collection(deck: _deck, holdingsByCardId: {
      'gnomon': Holding(
        card: _gnomon,
        standardCopies: standard,
        specialCopies: special,
      ),
    });

void main() {
  test('deck rows show progress from the deck list', () {
    String? selected;
    final rows = CollectionPresenter.deckRows(
      decks: const [
        DeckProgress(
            deckId: 'meridian', name: 'Meridian', cardsHeld: 4, cardsTotal: 6),
        DeckProgress(
            deckId: 'cinder', name: 'Cinder', cardsHeld: 0, cardsTotal: 6),
      ],
      selectedDeckId: 'cinder',
      isRail: false,
      onSelect: (deckId) => selected = deckId,
    );

    expect(rows.map((r) => r.name), ['Meridian', 'Cinder']);
    expect(rows.first.held, 4);
    expect(rows.first.total, 6);
    expect(rows.map((r) => r.isSelected), [false, true]);

    rows.first.onTap();
    expect(selected, 'meridian');
  });

  test('the empty deck uses its own draw cost', () {
    final params = CollectionPresenter.emptyDeck(
      deck: _deck,
      quarkBalance: 15,
      isDrawing: false,
      onDraw: () {},
    );

    expect(params.deckSize, 2);
    expect(params.drawLabel, 'Draw a card · 40 quarks');
    expect(params.canAfford, isFalse);
    expect(params.quarksShortLabel,
        'Solve questions to earn 25 more quarks.');
    expect(params.isDrawing, isFalse);
  });

  test('the draw button names its price in quarks', () {
    expect(CollectionPresenter.drawLabel(40), 'Draw a card · 40 quarks');
    expect(CollectionPresenter.drawLabel(1), 'Draw a card · 1 quark');
  });

  test('the quark balance says quark for one, and quarks for any other count',
      () {
    expect(CollectionPresenter.quarkBalanceLabel(1), '1 quark');
    expect(CollectionPresenter.quarkBalanceLabel(0), '0 quarks');
    expect(CollectionPresenter.quarkBalanceLabel(40), '40 quarks');
  });

  test('the shortfall says how to earn more', () {
    expect(CollectionPresenter.quarksShortLabel(40),
        'Solve questions to earn 40 more quarks.');
    expect(CollectionPresenter.quarksShortLabel(1),
        'Solve questions to earn 1 more quark.');
    expect(CollectionPresenter.quarksShortLabel(25),
        'Solve questions to earn 25 more quarks.');
  });

  test('the empty deck is told when a draw is in flight', () {
    final params = CollectionPresenter.emptyDeck(
      deck: _deck,
      quarkBalance: 40,
      isDrawing: true,
      onDraw: () {},
    );

    expect(params.isDrawing, isTrue);
  });

  group('the reveal line', () {
    test('for a new card is the deck progress after the draw', () {
      expect(
        CollectionPresenter.revealSupportingLine(
          outcome: _outcome(DrawResult.newCard),
          deckName: 'Meridian',
          collectionAfterDraw: _collectionWithGnomon(standard: 1, special: 0),
        ),
        '1 of 2 Meridian cards collected',
      );
    });

    test('for a new card, without the deck, is where it went', () {
      expect(
        CollectionPresenter.revealSupportingLine(
          outcome: _outcome(DrawResult.newCard),
          deckName: 'Meridian',
          collectionAfterDraw: null,
        ),
        'Added to Meridian',
      );
    });

    test('for an upgrade is that the plain copy stays', () {
      expect(
        CollectionPresenter.revealSupportingLine(
          outcome: _outcome(DrawResult.upgrade),
          deckName: 'Meridian',
          collectionAfterDraw: null,
        ),
        'You keep the standard one.',
      );
    });

    test('for a duplicate is what the card detail will offer', () {
      expect(
        CollectionPresenter.revealSupportingLine(
          outcome: _outcome(DrawResult.duplicate),
          deckName: 'Meridian',
          collectionAfterDraw: _collectionWithGnomon(standard: 2, special: 0),
        ),
        'Shatter one for 5 quarks',
      );
      // With no standard copy left the detail shatters a special one, so the
      // reveal must quote the special value too.
      expect(
        CollectionPresenter.revealSupportingLine(
          outcome: _outcome(DrawResult.duplicate),
          deckName: 'Meridian',
          collectionAfterDraw: _collectionWithGnomon(standard: 0, special: 2),
        ),
        'Shatter one for 10 quarks',
      );
    });

    test('for a duplicate, without the deck, names no number', () {
      expect(
        CollectionPresenter.revealSupportingLine(
          outcome: _outcome(DrawResult.duplicate),
          deckName: 'Meridian',
          collectionAfterDraw: null,
        ),
        'You can shatter a spare for quarks.',
      );
    });
  });

  group("a friend's collection", () {
    test('lists the decks with their progress, and no flags', () {
      final opened = <String>[];
      final rows = CollectionPresenter.friendDeckRows(
        decks: const [
          DeckProgress(
              deckId: 'cinder', name: 'Cinder', cardsHeld: 0, cardsTotal: 6),
          DeckProgress(
              deckId: 'meridian',
              name: 'Meridian',
              cardsHeld: 6,
              cardsTotal: 6),
        ],
        onSelect: opened.add,
      );

      expect([for (final row in rows) (row.name, row.held, row.total)],
          [('Cinder', 0, 6), ('Meridian', 6, 6)]);
      expect(rows.every((row) => !row.showFlag && !row.isSelected), isTrue);
      rows.last.onTap();
      expect(opened, ['meridian']);
    });

    test("is headed with the friend's nickname", () {
      expect(CollectionPresenter.friendCardsTitle('Sam'), "Sam's cards");
    });

    test('is headed plainly before the nickname is known', () {
      expect(CollectionPresenter.friendCardsTitle(null), "Your friend's cards");
    });
  });

  test('the held line counts cards held, not copies', () {
    expect(
      CollectionPresenter.heldLabel(
          _collectionWithGnomon(standard: 3, special: 1)),
      '1 of 2 held',
    );
  });
}
