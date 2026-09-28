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
      onDraw: () {},
    );

    expect(params.deckSize, 2);
    expect(params.drawCost, 40);
    expect(params.canAfford, isFalse);
    expect(params.quarksShort, 25);
  });

  group('the reveal line', () {
    test('for a new card is the deck progress after the draw', () {
      expect(
        CollectionPresenter.revealSupportingLine(
          outcome: _outcome(DrawResult.newCard),
          deckName: 'Meridian',
          collectionAfterDraw: _collectionWithGnomon(standard: 1, special: 0),
        ),
        'Meridian is 1 of 2',
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
}
