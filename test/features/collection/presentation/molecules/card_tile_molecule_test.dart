import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/domain/entity/holding.dart';
import 'package:doormer/src/features/collection/presentation/atoms/collectible_card_atom.dart';
import 'package:doormer/src/features/collection/presentation/molecules/card_tile_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _card = CollectibleCard(
  id: 'gnomon',
  name: 'Gnomon',
  deckId: 'meridian',
  rarity: Rarity.common,
  scaleLabel: 'Small',
  artAsset: 'assets/cards/meridian/gnomon.png',
  description: 'd',
);

// CardTileMolecule reads ScreenUtil (.w/.r/.sp) while building, so — as with
// every other widget test in this feature — it must be pumped inside a
// ScreenUtilInit ancestor or those calls throw before any assertion runs.
Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  group('layersFor', () {
    test('one copy lies flat', () {
      expect(CardTileMolecule.layersFor(1), 0);
    });

    test('two copies gain one layer, opening to 3 degrees', () {
      expect(CardTileMolecule.layersFor(2), 1);
      expect(CardTileMolecule.anglesFor(2), const [3.0]);
    });

    test('three or more caps at two layers', () {
      expect(CardTileMolecule.layersFor(3), 2);
      expect(CardTileMolecule.layersFor(147), 2);
    });

    test('rear layers are ordered back to front', () {
      // Stack paints later children on top, so the steepest tilt must come
      // first or the deepest card lands in front of the shallower one.
      expect(CardTileMolecule.anglesFor(3), const [5.0, 2.5]);
      expect(CardTileMolecule.anglesFor(147), const [5.0, 2.5]);
    });
  });

  testWidgets('a single copy renders one card and no badge', (tester) async {
    await tester.pumpWidget(_host(
      const CardTileMolecule(
        holding: Holding(card: _card, standardCopies: 1, specialCopies: 0),
        width: 104,
      ),
    ));
    expect(find.text('Gnomon'), findsOneWidget);
    expect(find.textContaining('×'), findsNothing);
  });

  testWidgets('three copies show the count as a badge', (tester) async {
    await tester.pumpWidget(_host(
      const CardTileMolecule(
        holding: Holding(card: _card, standardCopies: 3, specialCopies: 0),
        width: 104,
      ),
    ));
    expect(find.text('×3'), findsOneWidget);
  });

  testWidgets('rear layers sit behind the card and tilt from the bottom',
      (tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(
      const CardTileMolecule(
        holding: Holding(card: _card, standardCopies: 3, specialCopies: 0),
        width: 104,
      ),
    ));

    final stack = tester.widget<Stack>(
      find
          .descendant(
            of: find.byType(CardTileMolecule),
            matching: find.byType(Stack),
          )
          .first,
    );

    // Two rear layers, then the card itself, in that order.
    expect(stack.children.length, 3);
    expect(stack.children.last, isA<CollectibleCardAtom>(),
        reason: 'the art must be the front-most child');

    final rear = stack.children.take(2).cast<Transform>().toList();
    for (final layer in rear) {
      expect(layer.alignment, Alignment.bottomCenter);
    }
  });

  testWidgets('lifts about 5px while pressed, and settles back on release',
      (tester) async {
    await tester.pumpWidget(_host(
      CardTileMolecule(
        holding:
            const Holding(card: _card, standardCopies: 1, specialCopies: 0),
        width: 104,
        onTap: () {},
      ),
    ));

    double liftY() {
      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(CardTileMolecule),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return container.transform?.getTranslation().y ?? 0.0;
    }

    expect(liftY(), 0.0, reason: 'resting flat before any press');

    final gesture = await tester
        .startGesture(tester.getCenter(find.byType(CardTileMolecule)));
    await tester.pump(const Duration(milliseconds: 150));
    expect(liftY(), lessThan(0.0), reason: 'pressing should lift the tile');

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 150));
    expect(liftY(), 0.0, reason: 'releasing should settle it back down');
  });
}
