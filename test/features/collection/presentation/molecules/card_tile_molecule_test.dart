import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/domain/entity/holding.dart';
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

    test('two copies gain one layer', () {
      expect(CardTileMolecule.layersFor(2), 1);
    });

    test('three or more caps at two layers', () {
      expect(CardTileMolecule.layersFor(3), 2);
      expect(CardTileMolecule.layersFor(147), 2);
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
}
