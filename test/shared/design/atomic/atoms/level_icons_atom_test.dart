import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/shared/design/atomic/atoms/level_icon_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/level_icons_atom.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _sun = LevelIcon.sun;
const _moon = LevelIcon.moon;
const _star = LevelIcon.star;

/// [child] on the 360 by 690 design phone, where `1.w` is one pixel.
Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(360, 690);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: Center(child: child)),
    ),
  ));
}

/// [suns], [moons] and [stars], each 20 across, with no label.
LevelIconsAtom _icons({int suns = 0, int moons = 0, int stars = 0}) =>
    LevelIconsAtom(
      suns: suns,
      moons: moons,
      stars: stars,
      size: 20,
      semanticLabel: null,
    );

/// The icons drawn, from left to right, each with its left edge measured
/// from the row's.
List<(LevelIcon, double)> _drawn(WidgetTester tester) {
  final rowLeft = tester.getTopLeft(find.byType(LevelIconsAtom)).dx;
  final icons = find.byType(LevelIconAtom);
  return [
    for (var i = 0; i < icons.evaluate().length; i++)
      (
        tester.widget<LevelIconAtom>(icons.at(i)).icon,
        tester.getTopLeft(icons.at(i)).dx - rowLeft,
      ),
  ]..sort((a, b) => a.$2.compareTo(b.$2));
}

void main() {
  testWidgets('level 0 draws nothing', (tester) async {
    await _pump(tester, _icons());

    expect(find.byType(LevelIconAtom), findsNothing);
    expect(tester.getSize(find.byType(LevelIconsAtom)), Size.zero);
  });

  for (final (name, icons, expected) in [
    ('level 1 is a star', _icons(stars: 1), [_star]),
    ('level 4 is a moon', _icons(moons: 1), [_moon]),
    (
      'level 21 is a sun, a moon and a star, in that order',
      _icons(suns: 1, moons: 1, stars: 1),
      [_sun, _moon, _star],
    ),
    ('level 64 is four suns', _icons(suns: 4), [_sun, _sun, _sun, _sun]),
  ]) {
    testWidgets(name, (tester) async {
      await _pump(tester, icons);

      expect([for (final (icon, _) in _drawn(tester)) icon], expected);
    });
  }

  testWidgets(
      'icons of one kind sit 1 apart, and the kinds 5 apart, so the row reads '
      'as groups', (tester) async {
    // Level 25: a sun, two moons and a star.
    await _pump(tester, _icons(suns: 1, moons: 2, stars: 1));

    expect(_drawn(tester), [
      (_sun, 0.0),
      (_moon, 25.0),
      (_moon, 46.0),
      (_star, 71.0),
    ]);
    expect(tester.getSize(find.byType(LevelIconsAtom)), const Size(91, 20));
  });

  testWidgets('each icon is the size it is given', (tester) async {
    await _pump(tester, _icons(suns: 1, moons: 1, stars: 1));

    for (final icon in tester.widgetList(find.byType(LevelIconAtom))) {
      expect(tester.getSize(find.byWidget(icon)), const Size(20, 20));
    }
  });

  testWidgets('screen readers hear the label it is given', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      const LevelIconsAtom(
        suns: 0,
        moons: 1,
        stars: 2,
        size: 20,
        semanticLabel: 'Level 6',
      ),
    );

    expect(
      tester.getSemantics(find.byType(LevelIconsAtom)),
      containsSemantics(label: 'Level 6'),
    );
    semantics.dispose();
  });

  testWidgets('with no label, screen readers hear only the words beside it',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      MergeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _icons(suns: 1, moons: 1, stars: 1),
            const Text('Level 21'),
          ],
        ),
      ),
    );

    expect(tester.getSemantics(find.text('Level 21')).label, 'Level 21');
    semantics.dispose();
  });
}
