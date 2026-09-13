import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/presentation/organisms/empty_deck_organism.dart';
import 'package:doormer/src/features/collection/presentation/params/empty_deck_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

EmptyDeckParams _params({
  bool canAfford = true,
  int pointsShort = 0,
  VoidCallback? onDraw,
}) =>
    EmptyDeckParams(
      deckSize: 6,
      rarityMix: const {Rarity.common: 3, Rarity.uncommon: 2, Rarity.rare: 1},
      drawCost: 40,
      canAfford: canAfford,
      pointsShort: pointsShort,
      onDraw: onDraw ?? () {},
    );

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        home: Scaffold(body: SizedBox(width: 332, height: 600, child: child)),
      ),
    );

/// The default 800x600 test viewport is wider than the 360 design canvas, so
/// ScreenUtil overscales every dimension and this tall screen (closed deck +
/// headline + count + chips + button + shortfall line) overflows before an
/// assertion ever sees the real layout. Match the design canvas so the test
/// measures the widget, not the harness.
void _pinDesignViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 690);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('says nothing here yet, which is not a failure', (tester) async {
    _pinDesignViewport(tester);
    await tester.pumpWidget(_host(EmptyDeckOrganism(params: _params())));
    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('states the deck size in digits', (tester) async {
    _pinDesignViewport(tester);
    await tester.pumpWidget(_host(EmptyDeckOrganism(params: _params())));
    expect(find.text('6 cards to find'), findsOneWidget);
  });

  testWidgets('shows the mix as composition, never as odds', (tester) async {
    _pinDesignViewport(tester);
    await tester.pumpWidget(_host(EmptyDeckOrganism(params: _params())));
    expect(find.text('1 rare'), findsOneWidget);
    expect(find.text('2 uncommon'), findsOneWidget);
    expect(find.text('3 common'), findsOneWidget);
    // No percentage, chance or odds language anywhere.
    expect(find.textContaining('%'), findsNothing);
    expect(find.textContaining('chance'), findsNothing);
  });

  testWidgets('names no ship, hull or fleet', (tester) async {
    _pinDesignViewport(tester);
    await tester.pumpWidget(_host(EmptyDeckOrganism(params: _params())));
    for (final banned in ['ship', 'hull', 'fleet']) {
      expect(find.textContaining(banned), findsNothing);
    }
  });

  testWidgets('when affordable the draw button works', (tester) async {
    _pinDesignViewport(tester);
    var draws = 0;
    await tester.pumpWidget(_host(
      EmptyDeckOrganism(params: _params(onDraw: () => draws++)),
    ));
    await tester.tap(find.byType(AppButtonAtom));
    expect(draws, 1);
    expect(find.textContaining('more points'), findsNothing);
  });

  testWidgets('when unaffordable the button stays visible but disabled',
      (tester) async {
    _pinDesignViewport(tester);
    var draws = 0;
    await tester.pumpWidget(_host(EmptyDeckOrganism(
      params: _params(canAfford: false, pointsShort: 25, onDraw: () => draws++),
    )));

    expect(find.byType(AppButtonAtom), findsOneWidget,
        reason: 'hiding it would hide the price');
    expect(find.text('25 more points to draw'), findsOneWidget);

    await tester.tap(find.byType(AppButtonAtom));
    expect(draws, 0);
  });

  testWidgets('never tells the student how to earn points', (tester) async {
    _pinDesignViewport(tester);
    await tester.pumpWidget(_host(
      EmptyDeckOrganism(params: _params(canAfford: false, pointsShort: 25)),
    ));
    for (final banned in ['Ask', 'question', 'earn']) {
      expect(find.textContaining(banned), findsNothing);
    }
  });
}
