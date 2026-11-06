import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/profile/presentation/molecules/friend_row_molecule.dart';
import 'package:doormer/src/features/profile/presentation/params/friend_row_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/level_icons_atom.dart';
import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<String>> _pump(
  WidgetTester tester, {
  bool isBusy = false,
  Level? level,
  String? semanticsLabel,
}) async {
  final taps = <String>[];
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: FriendRowMolecule(
          params: FriendRowParams(
            nickname: 'Sam',
            artUrl: null,
            level: level,
            semanticsLabel: semanticsLabel,
            isBusy: isBusy,
            onOpen: () => taps.add('open'),
            onRemove: () => taps.add('remove'),
            onBlock: () => taps.add('block'),
            onReport: () => taps.add('report'),
          ),
        ),
      ),
    ),
  ));
  return taps;
}

void main() {
  testWidgets("shows the friend's picture and nickname", (tester) async {
    await _pump(tester);

    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('S'), findsOneWidget, reason: 'the first letter');
  });

  testWidgets('opens the friend', (tester) async {
    final taps = await _pump(tester);

    await tester.tap(find.text('Sam'));

    expect(taps, ['open']);
  });

  for (final action in ['Remove', 'Block', 'Report']) {
    testWidgets('the menu has $action', (tester) async {
      final taps = await _pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();

      expect(taps, [action.toLowerCase()]);
    });
  }

  testWidgets('while a change is on its way, waits and does nothing',
      (tester) async {
    final taps = await _pump(tester, isBusy: true);

    await tester.tap(find.text('Sam'));

    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(taps, isEmpty);
  });

  testWidgets(
      "shows the friend's level straight after the nickname, and screen "
      'readers hear the two together', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      level: const Level(number: 6, suns: 0, moons: 1, stars: 2),
      semanticsLabel: 'Sam, level 6',
    );

    final icons = find.byType(LevelIconsAtom);
    final drawn = tester.widget<LevelIconsAtom>(icons);
    expect((drawn.suns, drawn.moons, drawn.stars), (0, 1, 2));
    expect(drawn.size, 16.w);
    expect(tester.getRect(icons).left - tester.getRect(find.text('Sam')).right,
        moreOrLessEquals(6.w));
    expect(tester.getSemantics(find.text('Sam')).label, 'Sam, level 6');
    semantics.dispose();
  });

  testWidgets('a friend with no level shows no icons', (tester) async {
    await _pump(tester);

    expect(find.byType(LevelIconsAtom), findsNothing);
  });
}
