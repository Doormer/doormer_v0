import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/atoms/stat_pill_atom.dart';
import 'package:doormer/src/features/questions/presentation/organisms/quest_hud_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/quest_hud_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pump(QuestHudParams params) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: QuestHudOrganism(params: params)),
    ),
  );
}

void main() {
  testWidgets('shows the crumb, the question name and both pills',
      (tester) async {
    await tester.pumpWidget(_pump(const QuestHudParams(
      topic: 'Geometry - Area',
      questionTitle: 'Road through a field',
      quarkBalanceLabel: '128 quarks',
      streakLabel: '3-day',
    )));
    await tester.pump();

    expect(find.text('GEOMETRY - AREA'), findsOneWidget);
    expect(find.text('Road through a field'), findsOneWidget);
    expect(find.text('128 quarks'), findsOneWidget);
    expect(find.byKey(const Key('hud_quarks')), findsOneWidget);
    expect(find.text('3-day'), findsOneWidget);
  });

  testWidgets('omits a pill rather than showing a placeholder for it',
      (tester) async {
    await tester.pumpWidget(_pump(const QuestHudParams(
      topic: 'Geometry - Area',
      questionTitle: 'Road through a field',
      quarkBalanceLabel: '',
      streakLabel: '',
    )));
    await tester.pump();

    // A "0 quarks" that becomes "120 quarks" a frame later reads as losing
    // something, so a stat that has not loaded shows nothing at all.
    expect(find.byKey(const Key('hud_quarks')), findsNothing);
    expect(find.byKey(const Key('hud_streak')), findsNothing);
    expect(find.text('Road through a field'), findsOneWidget);
  });

  testWidgets('a long question name is truncated, not wrapped or overflowing',
      (tester) async {
    await tester.pumpWidget(_pump(const QuestHudParams(
      topic: 'Geometry - Area',
      questionTitle:
          'A road of uniform width crosses a rectangular field at an angle',
      quarkBalanceLabel: '128 quarks',
      streakLabel: '3-day',
    )));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('hands the stake down to the streak pill', (tester) async {
    await tester.pumpWidget(_pump(const QuestHudParams(
      topic: 'Geometry',
      questionTitle: 'Road through a field',
      quarkBalanceLabel: '128 quarks',
      streakLabel: '3-day',
      streakAtStake: true,
    )));
    await tester.pump();

    expect(
      tester.widget<StatPillAtom>(find.byKey(const Key('hud_streak'))).atStake,
      isTrue,
    );
    expect(
      tester.widget<StatPillAtom>(find.byKey(const Key('hud_quarks'))).atStake,
      isFalse,
      reason: 'earned quarks cannot be lost, so the balance is never at stake',
    );
  });

  testWidgets('the quark pill is amber and uses a dot', (tester) async {
    await tester.pumpWidget(_pump(const QuestHudParams(
      topic: 'Geometry',
      questionTitle: 'Road through a field',
      quarkBalanceLabel: '1 quark',
      streakLabel: '3-day',
    )));
    await tester.pump();

    final pill =
        tester.widget<StatPillAtom>(find.byKey(const Key('hud_quarks')));
    expect(pill.accent, QuestPalette.amber);
    expect(pill.leading, isNotNull);
    expect(pill.icon, isNull);
  });
}
