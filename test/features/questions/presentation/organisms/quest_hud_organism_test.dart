import 'package:doormer/src/core/theme/app_theme.dart';
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
      xpLabel: '135 XP',
      streakLabel: '3-day',
    )));
    await tester.pump();

    expect(find.text('GEOMETRY - AREA'), findsOneWidget);
    expect(find.text('Road through a field'), findsOneWidget);
    expect(find.text('135 XP'), findsOneWidget);
    expect(find.text('3-day'), findsOneWidget);
  });

  testWidgets('omits a pill rather than showing a placeholder for it',
      (tester) async {
    await tester.pumpWidget(_pump(const QuestHudParams(
      topic: 'Geometry - Area',
      questionTitle: 'Road through a field',
      xpLabel: '',
      streakLabel: '',
    )));
    await tester.pump();

    // A "0 XP" that becomes "120 XP" a frame later reads as losing something,
    // so an unloaded standing shows nothing at all.
    expect(find.byKey(const Key('hud_xp')), findsNothing);
    expect(find.byKey(const Key('hud_streak')), findsNothing);
    expect(find.text('Road through a field'), findsOneWidget);
  });

  testWidgets('a long question name is truncated, not wrapped or overflowing',
      (tester) async {
    await tester.pumpWidget(_pump(const QuestHudParams(
      topic: 'Geometry - Area',
      questionTitle:
          'A road of uniform width crosses a rectangular field at an angle',
      xpLabel: '135 XP',
      streakLabel: '3-day',
    )));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
