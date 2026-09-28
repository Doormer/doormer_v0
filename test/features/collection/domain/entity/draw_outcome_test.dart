// test/features/collection/domain/entity/draw_outcome_test.dart
import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/domain/entity/draw_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DrawResult headlines', () {
    test('are exactly the approved wording', () {
      expect(DrawResult.newCard.headline, 'A new one');
      expect(DrawResult.upgrade.headline, 'Now special');
      expect(DrawResult.duplicate.headline, 'Another one');
    });

    test('never name a ship, hull or fleet and never say duplicate', () {
      const banned = ['ship', 'hull', 'fleet', 'duplicate', 'copy', 'spare'];
      for (final result in DrawResult.values) {
        final lower = result.headline.toLowerCase();
        for (final word in banned) {
          expect(lower.contains(word), isFalse,
              reason: '"${result.headline}" must not contain "$word"');
        }
      }
    });
  });

  group('DrawOutcome', () {
    test('carries the count after the draw, for the badge', () {
      final outcome = DrawOutcome(
        card: const CollectibleCard(
          id: 'gnomon',
          name: 'Gnomon',
          deckId: 'meridian',
          rarity: Rarity.common,
          scaleLabel: 'Small',
          artUrl: 'https://example.test/a.jpg',
          standardShatterQuarks: 5,
          specialShatterQuarks: 10,
          description: 'd',
        ),
        variant: CardVariant.standard,
        result: DrawResult.duplicate,
        copiesAfter: 3,
      );
      expect(outcome.copiesAfter, 3);
      expect(outcome.result.headline, 'Another one');
    });
  });
}
