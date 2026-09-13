import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/presentation/atoms/collectible_card_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

CollectibleCard _card(Rarity rarity) => CollectibleCard(
      id: 'gnomon',
      name: 'Gnomon',
      deckId: 'meridian',
      rarity: rarity,
      scaleLabel: 'Small',
      artAsset: 'assets/cards/meridian/gnomon.png',
      description: 'd',
    );

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) =>
          MaterialApp(home: Scaffold(body: Center(child: child))),
    );

void main() {
  testWidgets('shows the card name', (tester) async {
    await tester.pumpWidget(_host(
      CollectibleCardAtom(card: _card(Rarity.common), width: 104),
    ));
    expect(find.text('Gnomon'), findsOneWidget);
  });

  testWidgets('a common card has no halo, so the halo still means something',
      (tester) async {
    expect(CollectibleCardAtom.haloFor(Rarity.common), isNull);
  });

  testWidgets('halo weight grows with scarcity', (tester) async {
    final uncommon = CollectibleCardAtom.haloFor(Rarity.uncommon)!;
    final rare = CollectibleCardAtom.haloFor(Rarity.rare)!;
    expect(rare.blurRadius, greaterThan(uncommon.blurRadius));
  });

  testWidgets('a card held once shows no count badge', (tester) async {
    await tester.pumpWidget(_host(
      CollectibleCardAtom(card: _card(Rarity.common), width: 104, copies: 1),
    ));
    expect(find.textContaining('×'), findsNothing);
  });

  testWidgets('a card held more than once shows the count as digits',
      (tester) async {
    await tester.pumpWidget(_host(
      CollectibleCardAtom(card: _card(Rarity.common), width: 104, copies: 147),
    ));
    expect(find.text('×147'), findsOneWidget);
  });

  testWidgets('the card keeps a 2:3 shape at any width', (tester) async {
    // The default 800x600 test viewport is shorter than 690 design px, so a
    // 200-wide card (scaled up from the 800-wide viewport) would be clipped
    // by its ancestor's height before this assertion ever saw its true shape.
    // Match the design canvas so the test measures the widget, not the harness.
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(
      CollectibleCardAtom(card: _card(Rarity.rare), width: 200),
    ));
    final box = tester.getSize(find.byType(CollectibleCardAtom));
    expect(box.height / box.width, closeTo(3 / 2, 0.01));
  });
}
