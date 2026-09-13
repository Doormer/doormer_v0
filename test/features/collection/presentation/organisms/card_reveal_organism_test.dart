import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/domain/entity/draw_outcome.dart';
import 'package:doormer/src/features/collection/presentation/organisms/card_reveal_organism.dart';
import 'package:doormer/src/features/collection/presentation/params/reveal_params.dart';
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

Widget _host(Widget child, {bool reduceMotion = false}) => ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Scaffold(body: child),
        ),
      ),
    );

DrawOutcome _outcome(DrawResultKind kind, {int copiesAfter = 1}) => DrawOutcome(
      card: _card,
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

    final state = tester.state<CardRevealState>(find.byType(CardRevealOrganism));
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

    final state = tester.state<CardRevealState>(find.byType(CardRevealOrganism));

    // Mid-flip: the card is still turning, so the result must not be announced.
    await tester.pump(const Duration(milliseconds: 850));
    expect(state.headlineOpacity, 0.0,
        reason: 'announcing the result mid-flip spoils the reveal');

    // After the flip has finished, it arrives.
    await tester.pump(const Duration(milliseconds: 600));
    expect(state.headlineOpacity, greaterThan(0.0));
  });

  testWidgets('a rare draw gets the flourish and a common one does not',
      (tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<int> glowCount(Rarity rarity) async {
      await tester.pumpWidget(_host(CardRevealOrganism(
        key: ValueKey(rarity),
        params: RevealParams(
          outcome: DrawOutcome(
            card: CollectibleCard(
              id: 'x',
              name: 'X',
              deckId: 'meridian',
              rarity: rarity,
              scaleLabel: 'Small',
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
      await tester.pump(const Duration(milliseconds: 900));
      return tester.widgetList(find.byType(Transform)).length;
    }

    final rare = await glowCount(Rarity.rare);
    final common = await glowCount(Rarity.common);
    expect(rare, greaterThan(common),
        reason: 'if every draw bloomed, none would mean anything');
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
    final state = tester.state<CardRevealState>(find.byType(CardRevealOrganism));
    expect(state.headlineOpacity, closeTo(1.0, 0.001),
        reason: 'motion off must cost movement, never information');
  });
}
