// test/features/collection/domain/entity/draw_outcome_test.dart
import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/domain/entity/draw_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DrawResultKind headlines', () {
    test('are exactly the approved wording', () {
      expect(DrawResultKind.newCard.headline, 'A new one');
      expect(DrawResultKind.upgrade.headline, 'Now special');
      expect(DrawResultKind.duplicate.headline, 'Another one');
    });

    test('never name a ship, hull or fleet and never say duplicate', () {
      const banned = ['ship', 'hull', 'fleet', 'duplicate', 'copy', 'spare'];
      for (final kind in DrawResultKind.values) {
        final lower = kind.headline.toLowerCase();
        for (final word in banned) {
          expect(lower.contains(word), isFalse,
              reason: '"${kind.headline}" must not contain "$word"');
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
          artAsset: 'a.png',
          description: 'd',
        ),
        variant: CardVariant.standard,
        kind: DrawResultKind.duplicate,
        copiesAfter: 3,
      );
      expect(outcome.copiesAfter, 3);
      expect(outcome.kind.headline, 'Another one');
    });
  });
}
