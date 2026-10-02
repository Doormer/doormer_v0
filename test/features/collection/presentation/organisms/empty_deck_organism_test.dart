import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/presentation/organisms/empty_deck_organism.dart';
import 'package:doormer/src/features/collection/presentation/params/empty_deck_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

EmptyDeckParams _params({
  int deckSize = 6,
  bool canAfford = true,
  bool isDrawing = false,
  VoidCallback? onDraw,
}) =>
    EmptyDeckParams(
      deckSize: deckSize,
      rarityMix: const {Rarity.common: 3, Rarity.uncommon: 2, Rarity.rare: 1},
      drawCost: 40,
      canAfford: canAfford,
      quarksShortLabel: '25 more quarks to draw',
      isDrawing: isDrawing,
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

  testWidgets('says card, not cards, for a deck of one', (tester) async {
    _pinDesignViewport(tester);
    await tester
        .pumpWidget(_host(EmptyDeckOrganism(params: _params(deckSize: 1))));
    expect(find.text('1 card to find'), findsOneWidget);
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
    expect(find.textContaining('odds'), findsNothing);
  });

  testWidgets('lists the rarest first, because that chip is the pull',
      (tester) async {
    _pinDesignViewport(tester);
    await tester.pumpWidget(_host(EmptyDeckOrganism(params: _params())));
    final chips = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .where((s) =>
            s.endsWith('rare') ||
            s.endsWith('uncommon') ||
            s.endsWith('common'))
        .toList();
    expect(chips, ['1 rare', '2 uncommon', '3 common']);
  });

  testWidgets(
      'a rarity the deck does not contain is omitted, not shown as zero',
      (tester) async {
    _pinDesignViewport(tester);
    await tester.pumpWidget(_host(EmptyDeckOrganism(
      params: EmptyDeckParams(
        deckSize: 3,
        rarityMix: const {Rarity.common: 3, Rarity.uncommon: 0, Rarity.rare: 0},
        drawCost: 40,
        canAfford: true,
        quarksShortLabel: '',
        isDrawing: false,
        onDraw: () {},
      ),
    )));
    expect(find.text('3 common'), findsOneWidget);
    expect(find.textContaining('0 rare'), findsNothing);
    expect(find.textContaining('0 uncommon'), findsNothing);
  });

  testWidgets('the price stays visible even when the draw is disabled',
      (tester) async {
    _pinDesignViewport(tester);
    await tester.pumpWidget(_host(
      EmptyDeckOrganism(params: _params(canAfford: false)),
    ));
    expect(find.textContaining('40'), findsWidgets,
        reason: 'disabling the button must not hide what a draw costs');
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
    expect(find.textContaining('more quarks'), findsNothing);
  });

  testWidgets('when unaffordable the button stays visible but disabled',
      (tester) async {
    _pinDesignViewport(tester);
    var draws = 0;
    await tester.pumpWidget(_host(EmptyDeckOrganism(
      params: _params(canAfford: false, onDraw: () => draws++),
    )));

    expect(find.byType(AppButtonAtom), findsOneWidget,
        reason: 'hiding it would hide the price');
    expect(find.text('25 more quarks to draw'), findsOneWidget);

    await tester.tap(find.byType(AppButtonAtom));
    expect(draws, 0);
  });

  testWidgets('while a draw is in flight the button spins and cannot be tapped',
      (tester) async {
    _pinDesignViewport(tester);
    var draws = 0;
    await tester.pumpWidget(_host(EmptyDeckOrganism(
      params: _params(isDrawing: true, onDraw: () => draws++),
    )));

    expect(tester.widget<AppButtonAtom>(find.byType(AppButtonAtom)).isLoading,
        isTrue);
    await tester.tap(find.byType(AppButtonAtom));
    expect(draws, 0);
  });

  testWidgets('never tells the student how to earn quarks', (tester) async {
    _pinDesignViewport(tester);
    await tester.pumpWidget(_host(
      EmptyDeckOrganism(params: _params(canAfford: false)),
    ));
    for (final banned in ['Ask', 'question', 'earn']) {
      expect(find.textContaining(banned), findsNothing);
    }
  });
}
