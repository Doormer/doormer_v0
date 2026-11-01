import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/level_icons_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sun = Icons.wb_sunny_rounded;
const _moon = Icons.nightlight_round;
const _star = Icons.star_rounded;

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: Center(child: child)),
    );

/// [suns], [moons] and [stars], each 20 across, with no label.
LevelIconsAtom _icons({int suns = 0, int moons = 0, int stars = 0}) =>
    LevelIconsAtom(
      suns: suns,
      moons: moons,
      stars: stars,
      size: 20,
      semanticLabel: null,
    );

/// The icons drawn, from left to right.
List<IconData?> _iconsLeftToRight(WidgetTester tester) {
  final icons = find.descendant(
    of: find.byType(LevelIconsAtom),
    matching: find.byType(Icon),
  );
  final drawn = [
    for (var i = 0; i < icons.evaluate().length; i++)
      (
        left: tester.getTopLeft(icons.at(i)).dx,
        icon: tester.widget<Icon>(icons.at(i)).icon,
      ),
  ]..sort((a, b) => a.left.compareTo(b.left));
  return [for (final shown in drawn) shown.icon];
}

void main() {
  testWidgets('level 0 draws nothing', (tester) async {
    await tester.pumpWidget(_host(_icons()));

    expect(find.byType(Icon), findsNothing);
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
      await tester.pumpWidget(_host(icons));

      expect(_iconsLeftToRight(tester), expected);
    });
  }

  testWidgets('stars and suns are amber, moons cream', (tester) async {
    await tester.pumpWidget(_host(_icons(suns: 1, moons: 1, stars: 1)));

    Color? colourOf(IconData icon) =>
        tester.widget<Icon>(find.byIcon(icon)).color;
    expect(colourOf(_sun), QuestPalette.amber);
    expect(colourOf(_moon), QuestPalette.cream);
    expect(colourOf(_star), QuestPalette.amber);
  });

  testWidgets('each icon is the size it is given', (tester) async {
    await tester.pumpWidget(_host(_icons(suns: 1, moons: 1, stars: 1)));

    expect(tester.getSize(find.byIcon(_moon)), const Size(20, 20));
    expect(tester.getSize(find.byType(LevelIconsAtom)), const Size(60, 20));
  });

  testWidgets('screen readers hear the label it is given', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host(const LevelIconsAtom(
      suns: 0,
      moons: 1,
      stars: 2,
      size: 20,
      semanticLabel: 'Level 6',
    )));

    expect(
      tester.getSemantics(find.byType(LevelIconsAtom)),
      containsSemantics(label: 'Level 6'),
    );
    semantics.dispose();
  });

  testWidgets('with no label, screen readers hear only the words beside it',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host(MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _icons(suns: 1, moons: 1, stars: 1),
          const Text('Level 21'),
        ],
      ),
    )));

    expect(tester.getSemantics(find.text('Level 21')).label, 'Level 21');
    semantics.dispose();
  });
}
