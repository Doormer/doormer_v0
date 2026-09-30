import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/presentation/atoms/collectible_card_atom.dart';
import 'package:doormer/src/features/collection/presentation/molecules/shattered_copy_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shoelace formula.
double _areaOf(Shard shard) {
  final points = shard.points;
  var twice = 0.0;
  for (var i = 0; i < points.length; i++) {
    final a = points[i];
    final b = points[(i + 1) % points.length];
    twice += a.dx * b.dy - b.dx * a.dy;
  }
  return twice.abs() / 2;
}

const _card = CollectibleCard(
  id: 'gnomon',
  name: 'Gnomon',
  rarity: Rarity.common,
  scaleLabel: 'Small',
  artUrl: 'https://example.test/gnomon.jpg',
  standardShatterQuarks: 5,
  specialShatterQuarks: 10,
  description: 'Gnomon.',
);

const _cardRect = Rect.fromLTWH(100, 120, 158, 237);

/// A common copy of Gnomon, worth 5 quarks, shattered [progress] of the way.
/// The molecule fills the screen, so its coordinates are the screen's.
Future<void> _pumpAt(WidgetTester tester, double progress) async {
  tester.view.physicalSize = const Size(360, 690);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      home: Scaffold(
        body: Stack(children: [
          Positioned.fill(
            child: ShatteredCopyMolecule(
              card: _card,
              isSpecial: false,
              cardWidth: 158,
              cardRect: _cardRect,
              quarkDotCentre: const Offset(40, 30),
              shards: ShatteredCopyMolecule.shardsFor(Rarity.common, 1),
              quarksGained: 5,
              progress: progress,
            ),
          ),
        ]),
      ),
    ),
  ));
}

void main() {
  group('shards', () {
    test('a common breaks into 6 shards, an uncommon 8 and a rare 11', () {
      expect(ShatteredCopyMolecule.shardsFor(Rarity.common, 1), hasLength(6));
      expect(ShatteredCopyMolecule.shardsFor(Rarity.uncommon, 1), hasLength(8));
      expect(ShatteredCopyMolecule.shardsFor(Rarity.rare, 1), hasLength(11));
    });

    test('the shards cover the card exactly, and nothing lies outside it', () {
      for (final rarity in Rarity.values) {
        for (var seed = 0; seed < 50; seed++) {
          final shards = ShatteredCopyMolecule.shardsFor(rarity, seed);
          final area = shards.map(_areaOf).reduce((a, b) => a + b);
          expect(area, closeTo(1, 1e-9), reason: '$rarity, seed $seed');
          for (final point in shards.expand((shard) => shard.points)) {
            expect(point.dx, inInclusiveRange(0, 1));
            expect(point.dy, inInclusiveRange(0, 1));
          }
        }
      }
    });

    test('every shard starts where the copy was struck, near its middle', () {
      for (var seed = 0; seed < 50; seed++) {
        final shards = ShatteredCopyMolecule.shardsFor(Rarity.rare, seed);
        final struck = shards.first.points.first;
        expect(struck.dx, inInclusiveRange(0.4, 0.6));
        expect(struck.dy, inInclusiveRange(0.35, 0.55));
        for (final shard in shards) {
          expect(shard.points.first, struck);
        }
      }
    });

    test('the same seed cuts the same shards, and another seed cuts others',
        () {
      List<List<Offset>> cut(int seed) => [
            for (final shard
                in ShatteredCopyMolecule.shardsFor(Rarity.uncommon, seed))
              shard.points,
          ];
      expect(cut(7), cut(7));
      expect(cut(7), isNot(cut(8)));
    });

    test('the seed comes from the card and the copies left', () {
      expect(ShatteredCopyMolecule.seedFor('ab', 0), 3105,
          reason: 'worked out by hand: hashCode differs between platforms');
      expect(ShatteredCopyMolecule.seedFor('gnomon', 2),
          ShatteredCopyMolecule.seedFor('gnomon', 2));
      expect(ShatteredCopyMolecule.seedFor('gnomon', 2),
          isNot(ShatteredCopyMolecule.seedFor('gnomon', 1)));
      expect(ShatteredCopyMolecule.seedFor('gnomon', 2),
          isNot(ShatteredCopyMolecule.seedFor('vernier', 2)));
    });
  });

  group('drawing', () {
    testWidgets('at 0 the shards sit exactly on the card', (tester) async {
      await _pumpAt(tester, 0);

      expect(find.byType(CollectibleCardAtom), findsNWidgets(6));
      for (var i = 0; i < 6; i++) {
        expect(tester.getRect(find.byKey(ValueKey('shard-$i'))),
            rectMoreOrLessEquals(_cardRect));
      }
      expect(find.textContaining('quarks'), findsNothing);
    });

    testWidgets('midway the shards have flown apart, and "+5 quarks" rises',
        (tester) async {
      await _pumpAt(tester, 0.4);

      for (var i = 0; i < 6; i++) {
        expect(tester.getRect(find.byKey(ValueKey('shard-$i'))),
            isNot(rectMoreOrLessEquals(_cardRect)));
      }
      expect(find.text('+5 quarks'), findsOneWidget);
    });

    testWidgets('the quark dots fly into the balance one after another',
        (tester) async {
      await _pumpAt(tester, 0.8);

      expect(find.byType(CollectibleCardAtom), findsNothing,
          reason: 'every shard has become a quark dot');
      expect(find.byKey(const ValueKey('quark-dot-0')), findsNothing,
          reason: 'the first quark dot has landed');
      expect(find.byKey(const ValueKey('quark-dot-5')), findsOneWidget,
          reason: 'the last one is still on its way');
    });

    testWidgets('at 1 nothing is left', (tester) async {
      await _pumpAt(tester, 1);

      expect(find.byType(CollectibleCardAtom), findsNothing);
      expect(find.byKey(const ValueKey('quark-dot-5')), findsNothing);
      expect(find.textContaining('quarks'), findsNothing);
    });

    test('the quark dots land one after another, the last at 0.9', () {
      expect(ShatteredCopyMolecule.quarkDotsLandedAt(0.5, 6), 0);
      expect(ShatteredCopyMolecule.quarkDotsLandedAt(0.8, 6), 2);
      expect(ShatteredCopyMolecule.quarkDotsLandedAt(0.91, 6), 6);
      expect(ShatteredCopyMolecule.quarkDotsLandedAt(1, 11), 11);
    });
  });
}
