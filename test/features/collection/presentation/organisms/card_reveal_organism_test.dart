import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/domain/entity/draw_outcome.dart';
import 'package:doormer/src/features/collection/presentation/organisms/card_reveal_organism.dart';
import 'package:doormer/src/features/collection/presentation/params/reveal_params.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
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

const _rareCard = CollectibleCard(
  id: 'orrery',
  name: 'The Orrery',
  deckId: 'meridian',
  rarity: Rarity.rare,
  scaleLabel: 'Capital',
  artAsset: 'assets/cards/meridian/gnomon.png',
  description: 'd',
);

Widget _host(Widget child, {bool reduceMotion = false}) => ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Scaffold(body: child),
        ),
      ),
    );

DrawOutcome _outcome(
  DrawResultKind kind, {
  int copiesAfter = 1,
  CollectibleCard card = _card,
}) =>
    DrawOutcome(
      card: card,
      variant: CardVariant.standard,
      kind: kind,
      copiesAfter: copiesAfter,
    );

void main() {
  group('fanCountFor', () {
    test('is the count below the cap, so the fan is readable', () {
      expect(CardRevealOrganism.fanCountFor(1), 1);
      expect(CardRevealOrganism.fanCountFor(2), 2);
      expect(CardRevealOrganism.fanCountFor(3), 3);
    });

    test('caps at four, where it stops meaning a number', () {
      expect(CardRevealOrganism.fanCountFor(4), 4);
      expect(CardRevealOrganism.fanCountFor(147), 4);
    });
  });

  testWidgets('shows the approved headline for each outcome', (tester) async {
    for (final entry in {
      DrawResultKind.newCard: 'A new one',
      DrawResultKind.upgrade: 'Now special',
      DrawResultKind.duplicate: 'Another one',
    }.entries) {
      await tester.pumpWidget(_host(CardRevealOrganism(
        params: RevealParams(outcome: _outcome(entry.key), onDismiss: () {}),
      )));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
    }
  });

  testWidgets('with motion off the card is face up and readable, not frozen',
      (tester) async {
    await tester.pumpWidget(_host(
      CardRevealOrganism(
        params: RevealParams(
          outcome: _outcome(DrawResultKind.newCard),
          onDismiss: () {},
        ),
      ),
      reduceMotion: true,
    ));
    await tester.pump();

    final state =
        tester.state<CardRevealState>(find.byType(CardRevealOrganism));
    expect(state.rotation, closeTo(1.0, 0.001),
        reason: 'must arrive at the face-up end, never stop mid-flip');
    expect(find.text('Gnomon'), findsOneWidget);
  });

  testWidgets('the glow collapses with the card so no ghost shows at 90°',
      (tester) async {
    await tester.pumpWidget(_host(CardRevealOrganism(
      params: RevealParams(
        outcome: _outcome(DrawResultKind.newCard),
        onDismiss: () {},
      ),
    )));
    // Edge-on: the card has no width, so neither may the glow.
    expect(CardRevealOrganism.glowScaleX(0.5), lessThan(0.05));
    // Face up and face down: full width.
    expect(CardRevealOrganism.glowScaleX(0.0), closeTo(1.0, 0.001));
    expect(CardRevealOrganism.glowScaleX(1.0), closeTo(1.0, 0.001));
  });

  testWidgets('the card lifts to its full height exactly as it turns edge-on',
      (tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(CardRevealOrganism(
      params: RevealParams(
        outcome: _outcome(DrawResultKind.newCard),
        onDismiss: () {},
      ),
    )));

    final state =
        tester.state<CardRevealState>(find.byType(CardRevealOrganism));
    var peakLift = 0.0;
    var peakScale = 1.0;
    var minGround = 1.0;
    var liftAtEdgeOn = 0.0;
    var closestToEdgeOn = 1.0;

    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      if (state.lift < peakLift) peakLift = state.lift;
      if (state.cardScale > peakScale) peakScale = state.cardScale;
      if (state.groundScale < minGround) minGround = state.groundScale;
      final distance = (state.rotation - 0.5).abs();
      if (distance < closestToEdgeOn) {
        closestToEdgeOn = distance;
        liftAtEdgeOn = state.lift;
      }
    }

    // Sampling every 20ms of a 416ms flip lands within ~2.5% of the true peak.
    expect(peakLift, lessThan(-11.0), reason: 'the mockup lifts 12px');
    expect(peakScale, greaterThan(1.05), reason: 'the mockup grows to 1.06');
    expect(minGround, lessThan(0.70), reason: 'the shadow contracts to 0.62');

    // The point of the whole gesture: keying these to the eased rotation put
    // the peak after the card was already turning back, and halved it.
    expect(liftAtEdgeOn, lessThan(-11.0),
        reason: 'the card must be at full height at the moment it is edge-on');
  });

  testWidgets('the tell is a ladder across rarities, not a switch',
      (tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Future<double> peakGlowFor(Rarity rarity) async {
      await tester.pumpWidget(_host(CardRevealOrganism(
        key: ValueKey(rarity),
        params: RevealParams(
          outcome: DrawOutcome(
            card: CollectibleCard(
              id: 'x',
              name: 'X',
              deckId: 'meridian',
              rarity: rarity,
              scaleLabel: 'S',
              artAsset: 'assets/cards/meridian/gnomon.png',
              description: 'd',
            ),
            variant: CardVariant.standard,
            kind: DrawResultKind.newCard,
            copiesAfter: 1,
          ),
          onDismiss: () {},
        ),
      )));
      final state =
          tester.state<CardRevealState>(find.byType(CardRevealOrganism));
      var peak = 0.0;
      for (var i = 0; i < 90; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        if (state.glowOpacity > peak) peak = state.glowOpacity;
      }
      return peak;
    }

    final common = await peakGlowFor(Rarity.common);
    final uncommon = await peakGlowFor(Rarity.uncommon);
    final rare = await peakGlowFor(Rarity.rare);

    // The spec's phase table: "Glow builds — strength scales with rarity".
    // Gating the glow on `isRare` made this a switch, and left a common draw
    // with no tell at all, which reads as a draw that failed.
    expect(common, greaterThan(0.0),
        reason: 'a common draw still settles, softly');
    expect(uncommon, greaterThan(common));
    expect(rare, greaterThan(uncommon));
  });

  testWidgets('a common draw settles in violet, because brass means rare',
      (tester) async {
    await tester.pumpWidget(_host(CardRevealOrganism(
      params: RevealParams(
        outcome: _outcome(DrawResultKind.newCard),
        onDismiss: () {},
      ),
    )));
    final state =
        tester.state<CardRevealState>(find.byType(CardRevealOrganism));
    expect(state.tellColour, QuestPalette.violet,
        reason:
            'brass is the rarity language; a common draw must not borrow it');
  });

  testWidgets('tapping dismisses', (tester) async {
    var dismissed = 0;
    await tester.pumpWidget(_host(CardRevealOrganism(
      params: RevealParams(
        outcome: _outcome(DrawResultKind.newCard),
        onDismiss: () => dismissed++,
      ),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CardRevealOrganism));
    expect(dismissed, 1);
  });

  testWidgets('the headline stays hidden until the card has landed',
      (tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(CardRevealOrganism(
      params: RevealParams(
        outcome: _outcome(DrawResultKind.newCard),
        onDismiss: () {},
      ),
    )));

    final state =
        tester.state<CardRevealState>(find.byType(CardRevealOrganism));

    // Mid-flip: the card is still turning, so the result must not be announced.
    await tester.pump(const Duration(milliseconds: 850));
    expect(state.headlineOpacity, 0.0,
        reason: 'announcing the result mid-flip spoils the reveal');

    // After the flip has finished, it arrives.
    await tester.pump(const Duration(milliseconds: 600));
    expect(state.headlineOpacity, greaterThan(0.0));
  });

  testWidgets(
      'a rare draw renders every flourish layer and a common one renders none',
      (tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // The rare-only layers from the spec: glow, rays, both rings, all four
    // motes, and the sweep. Ground shadow and the flip itself are deliberately
    // excluded — they belong to every rarity, so they would not distinguish
    // the two draws.
    const flourishKeys = [
      'reveal-rays',
      'reveal-ring-1',
      'reveal-ring-2',
      'reveal-mote-0',
      'reveal-mote-1',
      'reveal-mote-2',
      'reveal-mote-3',
      'reveal-sweep',
    ];

    Future<int> flourishLayerCount(CollectibleCard card) async {
      await tester.pumpWidget(_host(CardRevealOrganism(
        key: ValueKey(card.rarity),
        params: RevealParams(
          outcome: _outcome(DrawResultKind.newCard, card: card),
          onDismiss: () {},
        ),
      )));
      // Well into the landing, where every flourish layer is at its most
      // visible.
      await tester.pump(const Duration(milliseconds: 1500));
      return flourishKeys
          .where((k) => find.byKey(ValueKey(k)).evaluate().isNotEmpty)
          .length;
    }

    final rare = await flourishLayerCount(_rareCard);
    final common = await flourishLayerCount(_card);

    expect(rare, flourishKeys.length,
        reason: 'a rare draw should show every flourish layer');
    // The glow is deliberately NOT in that list: it is the tell, and the spec
    // grades its strength by rarity rather than switching it off. What a
    // common draw must not have is rays, rings, motes and sweep.
    expect(find.byKey(const ValueKey('reveal-glow')), findsOneWidget,
        reason: 'even a common draw settles, softly');
    expect(common, 0,
        reason: 'if every draw bloomed, none would mean anything');
    expect(rare, greaterThan(common));

    // The ground shadow is physics, not flourish, and belongs to both — still
    // present on the common draw left mounted by the loop above.
    expect(find.byKey(const ValueKey('reveal-ground')), findsOneWidget);
  });

  testWidgets('the glow builds during the tell, before the card turns',
      (tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(CardRevealOrganism(
      params: RevealParams(
        outcome: _outcome(DrawResultKind.newCard, card: _rareCard),
        onDismiss: () {},
      ),
    )));

    final state =
        tester.state<CardRevealState>(find.byType(CardRevealOrganism));

    // Mid-tell (0.12-0.40 of 1600ms): 400ms sits comfortably inside it.
    await tester.pump(const Duration(milliseconds: 400));
    expect(state.rotation, 0.0,
        reason: 'the card must not have started turning yet');
    expect(state.glowOpacity, greaterThan(0.0),
        reason: 'anticipation should build a beat before the turn');
  });

  testWidgets('under reduced motion the decorative loop does not run',
      (tester) async {
    await tester.pumpWidget(_host(
      CardRevealOrganism(
        params: RevealParams(
          outcome: _outcome(DrawResultKind.newCard, card: _rareCard),
          onDismiss: () {},
        ),
      ),
      reduceMotion: true,
    ));
    await tester.pump();

    final state =
        tester.state<CardRevealState>(find.byType(CardRevealOrganism));
    expect(state.flourishRunning, isFalse,
        reason:
            'a continuously-repeating loop must not run when motion is off');
  });

  testWidgets('ground shadow and lift apply to a common draw too',
      (tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(CardRevealOrganism(
      params: RevealParams(
        outcome: _outcome(DrawResultKind.newCard), // common
        onDismiss: () {},
      ),
    )));

    final state =
        tester.state<CardRevealState>(find.byType(CardRevealOrganism));

    // Mid-flip (0.40-0.66 of 1600ms): 850ms sits comfortably inside it.
    await tester.pump(const Duration(milliseconds: 850));
    expect(state.rotation, greaterThan(0.0));
    expect(state.rotation, lessThan(1.0));
    expect(state.lift, isNot(0.0),
        reason: 'the card should lift as it turns, even on a common draw');
    expect(state.groundScale, isNot(1.0),
        reason: 'the ground shadow should react to the lift');
    expect(find.byKey(const ValueKey('reveal-ground')), findsOneWidget);
  });

  testWidgets('with motion off the headline is fully arrived too',
      (tester) async {
    await tester.pumpWidget(_host(
      CardRevealOrganism(
        params: RevealParams(
          outcome: _outcome(DrawResultKind.newCard),
          onDismiss: () {},
        ),
      ),
      reduceMotion: true,
    ));
    await tester.pump();
    final state =
        tester.state<CardRevealState>(find.byType(CardRevealOrganism));
    expect(state.headlineOpacity, closeTo(1.0, 0.001),
        reason: 'motion off must cost movement, never information');
  });
}
