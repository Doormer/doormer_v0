import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/domain/entity/holding.dart';
import 'package:doormer/src/features/collection/presentation/molecules/card_tile_molecule.dart';
import 'package:doormer/src/features/collection/presentation/organisms/card_grid_organism.dart';
import 'package:doormer/src/shared/design/atomic/atoms/rise_in_atom.dart';
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
    // Counting tiles alone would still pass if placeholders of some other type
    // were appended, which is exactly the thing this rule forbids.
    final wrap = tester.widget<Wrap>(find.byType(Wrap));
    expect(wrap.children, isEmpty);
  });

  testWidgets('renders nothing beyond the held cards themselves',
      (tester) async {
    final holdings = [_holding('a'), _holding('b'), _holding('c')];
    await tester.pumpWidget(_host(CardGridOrganism(
      holdings: holdings,
      cardWidth: 104,
    )));
    final wrap = tester.widget<Wrap>(find.byType(Wrap));
    expect(wrap.children.length, holdings.length);
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

  testWidgets('cards arrive staggered by their position in the grid',
      (tester) async {
    await tester.pumpWidget(_host(CardGridOrganism(
      holdings: [_holding('a'), _holding('b'), _holding('c')],
      cardWidth: 104,
    )));

    // Each tile arrives through RiseInAtom, a beat behind the one before it —
    // rather than the whole grid appearing at once.
    final risers = tester.widgetList<RiseInAtom>(find.byType(RiseInAtom)).toList();
    expect(risers.map((w) => w.order).toList(), [0, 1, 2]);

    final tiles = find.byType(CardTileMolecule);
    for (var i = 0; i < 3; i++) {
      expect(
        find.descendant(
          of: find.byType(RiseInAtom).at(i),
          matching: tiles,
        ),
        findsOneWidget,
      );
    }
  });
}
