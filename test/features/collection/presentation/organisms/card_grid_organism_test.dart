import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/domain/entity/holding.dart';
import 'package:doormer/src/features/collection/presentation/molecules/card_tile_molecule.dart';
import 'package:doormer/src/features/collection/presentation/organisms/card_grid_organism.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Holding _holding(String id, {int copies = 1}) => Holding(
      card: CollectibleCard(
        id: id,
        name: id,
        deckId: 'meridian',
        rarity: Rarity.common,
        scaleLabel: 'Small',
        artAsset: 'assets/cards/meridian/gnomon.png',
        description: 'd',
      ),
      standardCopies: copies,
      specialCopies: 0,
    );

Widget _host(Widget child, {double width = 550}) => ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) =>
          MaterialApp(home: Scaffold(body: SizedBox(width: width, child: child))),
    );

void main() {
  testWidgets('renders one tile per held card and nothing for the rest',
      (tester) async {
    await tester.pumpWidget(_host(CardGridOrganism(
      holdings: [_holding('a'), _holding('b'), _holding('c')],
      cardWidth: 104,
    )));
    expect(find.byType(CardTileMolecule), findsNWidgets(3));
  });

  testWidgets('holds nothing when nothing is held, rather than empty frames',
      (tester) async {
    await tester.pumpWidget(_host(const CardGridOrganism(
      holdings: [],
      cardWidth: 104,
    )));
    expect(find.byType(CardTileMolecule), findsNothing);
  });

  testWidgets('uses Wrap so a partial last row can centre', (tester) async {
    await tester.pumpWidget(_host(CardGridOrganism(
      holdings: [_holding('a'), _holding('b'), _holding('c'), _holding('d')],
      cardWidth: 104,
    )));
    // GridView would reserve a full row and strand the fourth card left.
    expect(find.byType(GridView), findsNothing);
    final wrap = tester.widget<Wrap>(find.byType(Wrap));
    expect(wrap.alignment, WrapAlignment.center);
  });

  testWidgets('reports which card was tapped', (tester) async {
    String? tapped;
    await tester.pumpWidget(_host(CardGridOrganism(
      holdings: [_holding('a'), _holding('b')],
      cardWidth: 104,
      onCardTap: (h) => tapped = h.card.id,
    )));
    await tester.tap(find.byType(CardTileMolecule).last);
    expect(tapped, 'b');
  });
}
