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
        rarity: Rarity.common,
        scaleLabel: 'Small',
        artUrl: 'https://example.test/gnomon.jpg',
        standardShatterQuarks: 5,
        specialShatterQuarks: 10,
        description: 'd',
      ),
      standardCopies: copies,
      specialCopies: 0,
    );

Widget _host(Widget child, {double width = 550}) => ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
          home: Scaffold(body: SizedBox(width: width, child: child))),
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

  testWidgets('on a phone two cards fill the width, edge to edge',
      (tester) async {
    // The design asks for two grids, not one at two sizes: "Desktop centred,
    // phone fills the width, two columns, edge to edge" — a phone has no
    // spare horizontal space to give away.
    await tester.pumpWidget(_host(
      width: 332,
      CardGridOrganism(
        holdings: [_holding('a'), _holding('b')],
        cardWidth: 104,
        fillWidth: true,
      ),
    ));

    final first = tester.getRect(find.byType(CardTileMolecule).at(0));
    final second = tester.getRect(find.byType(CardTileMolecule).at(1));

    expect(first.left, closeTo(0, 1), reason: 'flush to the left edge');
    expect(second.right, closeTo(332, 1), reason: 'flush to the right edge');
    expect(first.width, greaterThan(140),
        reason: 'a filled column is far wider than the fixed 104');
  });

  testWidgets('on a wide window the cards stay fixed and centre',
      (tester) async {
    // Reproduces the template's own context. A Column with
    // CrossAxisAlignment.start lets its child shrink to its content, which is
    // what left-aligned the grid: the Wrap became exactly as wide as two
    // cards, so WrapAlignment.center had nothing to centre within.
    await tester.pumpWidget(_host(
      width: 700,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardGridOrganism(
            holdings: [_holding('a'), _holding('b')],
            cardWidth: 104,
          ),
        ],
      ),
    ));

    final first = tester.getRect(find.byType(CardTileMolecule).at(0));
    final second = tester.getRect(find.byType(CardTileMolecule).at(1));

    // Left-aligning here was the bug: inside a Column with
    // CrossAxisAlignment.start the Wrap shrank to its own content, leaving
    // WrapAlignment.center nothing to centre within.
    final leftGap = first.left;
    final rightGap = 700 - second.right;
    expect(leftGap, greaterThan(1), reason: 'not flush left');
    expect(leftGap, closeTo(rightGap, 2), reason: 'centred, not left-aligned');
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
    final risers =
        tester.widgetList<RiseInAtom>(find.byType(RiseInAtom)).toList();
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
