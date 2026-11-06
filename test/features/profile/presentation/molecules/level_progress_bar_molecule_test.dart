import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/profile/presentation/molecules/level_progress_bar_molecule.dart';
import 'package:doormer/src/shared/design/atomic/atoms/level_icon_atom.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _track = ValueKey('level-bar-track');
const _fill = ValueKey('level-bar-fill');

/// [bar], 300 wide, on the 360 by 690 design phone, where `1.w` and `1.h`
/// are one pixel.
Future<void> _pump(WidgetTester tester, LevelProgressBarMolecule bar) async {
  tester.view.physicalSize = const Size(360, 690);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(child: SizedBox(width: 300, child: bar)),
      ),
    ),
  ));
}

void main() {
  testWidgets("is empty on a level's first day", (tester) async {
    await _pump(
      tester,
      const LevelProgressBarMolecule(fill: 0, nextLevelIcon: LevelIcon.star),
    );

    expect(find.byKey(_track), findsOneWidget);
    expect(find.byKey(_fill), findsNothing);
  });

  testWidgets('fills the share of the level done, from the left',
      (tester) async {
    await _pump(
      tester,
      const LevelProgressBarMolecule(
        fill: 23 / 47,
        nextLevelIcon: LevelIcon.star,
      ),
    );

    final track = tester.getRect(find.byKey(_track));
    final fill = tester.getRect(find.byKey(_fill));
    expect(track.size, const Size(300, 10));
    expect(fill.left, track.left);
    expect(fill.width, moreOrLessEquals(300 * 23 / 47));
    expect(fill.height, track.height);
  });

  testWidgets("shows the next level's icon, faded, at the bar's end",
      (tester) async {
    await _pump(
      tester,
      const LevelProgressBarMolecule(fill: 0.5, nextLevelIcon: LevelIcon.moon),
    );

    final icon = find.byType(LevelIconAtom);
    expect(tester.widget<LevelIconAtom>(icon).icon, LevelIcon.moon);
    expect(
      tester
          .widget<Opacity>(
              find.ancestor(of: icon, matching: find.byType(Opacity)).first)
          .opacity,
      0.35,
    );
    final track = tester.getRect(find.byKey(_track));
    final drawn = tester.getRect(icon);
    expect(drawn.size, const Size(20, 20));
    expect(drawn.right, moreOrLessEquals(track.right + 6));
    expect(drawn.center.dy, moreOrLessEquals(track.center.dy));
  });
}
