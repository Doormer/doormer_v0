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
  testWidgets('shows the topic in capitals over the method', (tester) async {
    await tester.pumpWidget(_pump(const QuestHudParams(
      topic: 'Geometry - Area',
      method: 'Trigonometry and parallelogram area',
      quarkBalanceLabel: '128 quarks',
    )));
    await tester.pump();

    expect(find.text('GEOMETRY - AREA'), findsOneWidget);
    expect(find.text('Trigonometry and parallelogram area'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('hud_topic'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('hud_method'))).dy),
    );
  });

  testWidgets('a blank topic and method show nothing', (tester) async {
    await tester.pumpWidget(_pump(const QuestHudParams(
      topic: '',
      method: '',
      quarkBalanceLabel: '',
    )));
    await tester.pump();

    expect(tester.widget<Text>(find.byKey(const Key('hud_topic'))).data, '');
    expect(tester.widget<Text>(find.byKey(const Key('hud_method'))).data, '');
  });

  testWidgets('shows a method without a topic', (tester) async {
    await tester.pumpWidget(_pump(const QuestHudParams(
      topic: '',
      method: 'Completing the square',
      quarkBalanceLabel: '',
    )));
    await tester.pump();

    expect(tester.widget<Text>(find.byKey(const Key('hud_topic'))).data, '');
    expect(find.text('Completing the square'), findsOneWidget);
  });

  testWidgets('keeps its height when the quark pill arrives', (tester) async {
    await tester.pumpWidget(_pump(const QuestHudParams(
      topic: '',
      method: '',
      quarkBalanceLabel: '',
    )));
    await tester.pump();
    final before = tester.getSize(find.byKey(const Key('quest_hud'))).height;

    await tester.pumpWidget(_pump(const QuestHudParams(
      topic: '',
      method: '',
      quarkBalanceLabel: '128 quarks',
    )));
    await tester.pump();
    final after = tester.getSize(find.byKey(const Key('quest_hud'))).height;

    expect(after, before);
  });

  testWidgets('shows only one pill and no streak', (tester) async {
    await tester.pumpWidget(_pump(const QuestHudParams(
      topic: 'Geometry',
      method: 'Area of a parallelogram',
      quarkBalanceLabel: '128 quarks',
    )));
    await tester.pump();

    expect(find.byType(StatPillAtom), findsOneWidget);
    expect(find.byKey(const Key('hud_streak')), findsNothing);
  });

  testWidgets('omits the quark pill until the balance loads', (tester) async {
    await tester.pumpWidget(_pump(const QuestHudParams(
      topic: 'Geometry',
      method: 'Area of a parallelogram',
      quarkBalanceLabel: '',
    )));
    await tester.pump();

    expect(find.byKey(const Key('hud_quarks')), findsNothing);
  });

  testWidgets('a long method is cut to one line', (tester) async {
    await tester.pumpWidget(_pump(const QuestHudParams(
      topic: 'Geometry - Area',
      method:
          'Trigonometry and parallelogram area with a deliberately long explanation',
      quarkBalanceLabel: '128 quarks',
    )));
    await tester.pump();

    final method = tester.widget<Text>(find.byKey(const Key('hud_method')));
    expect(method.maxLines, 1);
    expect(method.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the quark pill is amber and uses a dot', (tester) async {
    await tester.pumpWidget(_pump(const QuestHudParams(
      topic: 'Geometry',
      method: 'Area of a parallelogram',
      quarkBalanceLabel: '1 quark',
    )));
    await tester.pump();

    final pill =
        tester.widget<StatPillAtom>(find.byKey(const Key('hud_quarks')));
    expect(pill.accent, QuestPalette.amber);
    expect(pill.leading, isNotNull);
    expect(pill.icon, isNull);
  });
}
