import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/profile/presentation/organisms/level_strip_organism.dart';
import 'package:doormer/src/features/profile/presentation/params/level_strip_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/level_icons_atom.dart';
import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _level21 = Level(number: 21, suns: 1, moons: 1, stars: 1);
const _line540 = '540 active days · 32 to your next star';

Future<void> _pump(WidgetTester tester, LevelStripParams params) =>
    tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: LevelStripOrganism(params: params),
          ),
        ),
      ),
    ));

LevelStripParams _strip({
  Level level = _level21,
  String title = 'Level 21',
  String line = _line540,
  VoidCallback? onExplain,
}) =>
    LevelStripParams(
      level: level,
      title: title,
      activeDaysLine: line,
      onExplain: onExplain ?? () {},
    );

void main() {
  testWidgets(
      'shows the icons, then the level with ⓘ straight after it, and the '
      'active days below', (tester) async {
    await _pump(tester, _strip());

    final icons = tester.getRect(find.byType(LevelIconsAtom));
    final title = tester.getRect(find.text('Level 21'));
    final info = tester.getRect(find.byTooltip('How levels work'));
    expect(icons.right, lessThanOrEqualTo(title.left));
    expect(info.left - title.right, inInclusiveRange(0, 16));
    expect(tester.getRect(find.text(_line540)).top,
        greaterThanOrEqualTo(title.bottom));
    final drawn = tester.widget<LevelIconsAtom>(find.byType(LevelIconsAtom));
    expect((drawn.suns, drawn.moons, drawn.stars), (1, 1, 1));
  });

  testWidgets('at level 0 shows "Level 0" alone, with no icons',
      (tester) async {
    await _pump(
      tester,
      _strip(
        level: const Level(number: 0, suns: 0, moons: 0, stars: 0),
        title: 'Level 0',
        line: '1 active day · 4 to your next star',
      ),
    );

    expect(find.byType(LevelIconsAtom), findsNothing);
    expect(find.text('Level 0'), findsOneWidget);
    expect(find.text('1 active day · 4 to your next star'), findsOneWidget);
  });

  testWidgets('ⓘ opens How levels work', (tester) async {
    var explained = 0;
    await _pump(tester, _strip(onExplain: () => explained++));

    await tester.tap(find.byTooltip('How levels work'));

    expect(explained, 1);
  });
}
