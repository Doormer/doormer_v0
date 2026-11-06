import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/levels/presentation/atoms/sunburst_atom.dart';
import 'package:doormer/src/features/levels/presentation/organisms/new_level_pop_up_organism.dart';
import 'package:doormer/src/features/levels/presentation/params/new_level_pop_up_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/level_icon_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/level_icons_atom.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _newStar = NewLevelPopUpParams(
  newIcon: LevelIcon.star,
  smallerIcon: null,
  title: 'New star!',
  levelLine: "You're level 5.",
  announcement: "New star! You're level 5.",
);

const _newMoon = NewLevelPopUpParams(
  newIcon: LevelIcon.moon,
  smallerIcon: LevelIcon.star,
  title: 'New moon!',
  levelLine: "You're level 4.",
  announcement: "New moon! You're level 4.",
);

const _newSun = NewLevelPopUpParams(
  newIcon: LevelIcon.sun,
  smallerIcon: LevelIcon.moon,
  title: 'New sun!',
  levelLine: "You're level 16.",
  announcement: "New sun! You're level 16.",
);

final _icon = find.byKey(const ValueKey('new-level-icon'));
final _flash = find.byKey(const ValueKey('new-level-flash'));
final _halo = find.byKey(const ValueKey('new-level-halo'));
final _recap = find.byKey(const ValueKey('new-level-recap'));
Finder _smaller(int index) => find.byKey(ValueKey('smaller-icon-$index'));
Finder _sparkle(int index) => find.byKey(ValueKey('sparkle-$index'));

/// [home] on the 360 by 690 design phone, where `1.w` is one pixel, with
/// motion on unless [reduceMotion].
Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = const Size(360, 690);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: Scaffold(body: home),
    ),
  ));
}

/// [home] in a [window], scaled as the app scales every screen: the app's
/// `ResponsiveAppShell` picks the scale, which stops at its floor of 0.85 on
/// a short window.
Future<void> _pumpInWindow(
  WidgetTester tester,
  Widget home, {
  required Size window,
}) async {
  tester.view.physicalSize = window;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    builder: (context, child) => ResponsiveAppShell(child: child!),
    home: Scaffold(body: home),
  ));
}

/// [params]' pop-up on its own, as it first shows.
Future<void> _pumpPopUp(
  WidgetTester tester,
  NewLevelPopUpParams params, {
  bool reduceMotion = false,
}) =>
    _pump(
      tester,
      NewLevelPopUpOrganism(params: params, onClose: () {}),
      reduceMotion: reduceMotion,
    );

/// Opens [params]' pop-up from a page, as the nav bar shell does, and lets
/// its first 0.2 s run: on the design phone, or in [window] as the app
/// scales it. Answers how many times it has closed so far.
Future<int Function()> _open(
  WidgetTester tester,
  NewLevelPopUpParams params, {
  Size? window,
}) async {
  var closed = 0;
  final page = Builder(
    builder: (context) => Center(
      child: TextButton(
        onPressed: () async {
          await showNewLevelPopUp(context, params);
          closed++;
        },
        child: const Text('Open'),
      ),
    ),
  );
  if (window == null) {
    await _pump(tester, page);
  } else {
    await _pumpInWindow(tester, page, window: window);
  }
  await tester.tap(find.text('Open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  return () => closed;
}

/// How opaque [finder] is drawn: the Opacity widgets above it, multiplied.
double _opacityOf(WidgetTester tester, Finder finder) => tester
    .widgetList<Opacity>(
        find.ancestor(of: finder, matching: find.byType(Opacity)))
    .fold(1.0, (opacity, widget) => opacity * widget.opacity);

/// The parts that keep moving once the pop-up has settled.
typedef _StillMoving = ({
  double turns,
  double haloWidth,
  double iconTop,
  List<double> sparkles,
});

_StillMoving _stillMoving(WidgetTester tester) => (
      turns: tester.widget<SunburstAtom>(find.byType(SunburstAtom)).turns,
      haloWidth: tester.getRect(_halo).width,
      iconTop: tester.getRect(_icon).top,
      sparkles: [for (var k = 0; k < 6; k++) _opacityOf(tester, _sparkle(k))],
    );

void main() {
  for (final (name, params, made) in [
    ('a new star shows its title and line, with no recap', _newStar, null),
    (
      'a new moon shows its title and line, and four stars making the moon',
      _newMoon,
      (moons: 0, stars: 4),
    ),
    (
      'a new sun shows its title and line, and four moons making the sun',
      _newSun,
      (moons: 4, stars: 0),
    ),
  ]) {
    testWidgets(name, (tester) async {
      await _pumpPopUp(tester, params, reduceMotion: true);

      expect(find.text(params.title), findsOneWidget);
      expect(find.text(params.levelLine), findsOneWidget);
      expect(find.text('Nice!'), findsOneWidget);
      expect(tester.widget<LevelIconAtom>(_icon).icon, params.newIcon);
      expect(tester.getSize(_icon), const Size(100, 100));
      if (made == null) {
        expect(_recap, findsNothing);
        return;
      }
      final four = tester.widget<LevelIconsAtom>(
          find.descendant(of: _recap, matching: find.byType(LevelIconsAtom)));
      expect((four.suns, four.moons, four.stars), (0, made.moons, made.stars));
      final sum = tester.widget<LevelIconAtom>(find
          .descendant(of: _recap, matching: find.byType(LevelIconAtom))
          .last);
      expect(sum.icon, params.newIcon);
    });
  }

  testWidgets(
      'screen readers hear the title and line together as it opens, and focus '
      'starts on Nice!, so Enter closes it', (tester) async {
    final semantics = tester.ensureSemantics();
    final closed = await _open(tester, _newMoon);

    expect(
      tester.getSemantics(find.bySemanticsLabel("New moon! You're level 4.")),
      containsSemantics(
        label: "New moon! You're level 4.",
        namesRoute: true,
        scopesRoute: true,
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(closed(), 1);
    semantics.dispose();
  });

  testWidgets('tapping Nice! closes it', (tester) async {
    final closed = await _open(tester, _newMoon);

    await tester.tap(find.text('Nice!'));
    await tester.pumpAndSettle();

    expect(closed(), 1);
    expect(find.byType(NewLevelPopUpOrganism), findsNothing);
  });

  testWidgets('the system back gesture closes it', (tester) async {
    final closed = await _open(tester, _newMoon);

    // The back button or gesture of a phone app, sent as a pop. On the
    // web the browser's back button goes to the router instead, which
    // leaves dialogs open.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(closed(), 1);
    expect(find.byType(NewLevelPopUpOrganism), findsNothing);
  });

  testWidgets('Escape closes it', (tester) async {
    final closed = await _open(tester, _newMoon);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(closed(), 1);
    expect(find.byType(NewLevelPopUpOrganism), findsNothing);
  });

  testWidgets('a tap outside the card closes it, and a tap on it does not',
      (tester) async {
    final closed = await _open(tester, _newMoon);

    await tester.tap(find.text('New moon!'));
    await tester.pump();
    expect(closed(), 0);
    expect(find.byType(NewLevelPopUpOrganism), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(closed(), 1);
    expect(find.byType(NewLevelPopUpOrganism), findsNothing);
  });

  for (final textScale in [1, 2]) {
    testWidgets(
        'on a short screen, such as a phone turned sideways, the card scrolls '
        'and Nice! still closes it, at text scale $textScale', (tester) async {
      // With motion off the pop-up stands still, so the frames can settle.
      tester.platformDispatcher
        ..accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true)
        ..textScaleFactorTestValue = textScale.toDouble();
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final closed =
          await _open(tester, _newMoon, window: const Size(740, 330));

      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Nice!'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nice!'));
      await tester.pumpAndSettle();

      expect(closed(), 1);
      expect(find.byType(NewLevelPopUpOrganism), findsNothing);
    });
  }

  testWidgets(
      'for a new moon, four stars pop in and fly together, then a flash, and '
      'the moon pops in before the words rise', (tester) async {
    await _pumpPopUp(tester, _newMoon);

    await tester.pump(const Duration(milliseconds: 700));
    for (var i = 0; i < 4; i++) {
      expect(_opacityOf(tester, _smaller(i)), 1.0, reason: 'star $i is in');
    }
    final apart =
        tester.getCenter(_smaller(3)).dx - tester.getCenter(_smaller(0)).dx;
    expect(apart, moreOrLessEquals(168, epsilon: 0.01));
    expect(_opacityOf(tester, _icon), 0.0, reason: 'the moon waits');
    expect(_opacityOf(tester, find.text('New moon!')), 0.0,
        reason: 'and so do the words');

    await tester.pump(const Duration(milliseconds: 250));
    final closer =
        tester.getCenter(_smaller(3)).dx - tester.getCenter(_smaller(0)).dx;
    expect(closer, lessThan(apart), reason: 'the stars fly together');

    await tester.pump(const Duration(milliseconds: 300));
    expect(_opacityOf(tester, _flash), greaterThan(0.5), reason: 'the flash');
    expect(_opacityOf(tester, _icon), 1.0, reason: 'the moon pops in');
    expect(tester.getRect(_icon).width, inExclusiveRange(20, 100));
    for (var i = 0; i < 4; i++) {
      expect(_opacityOf(tester, _smaller(i)), 0.0, reason: 'star $i merged');
    }

    await tester.pump(const Duration(milliseconds: 1350));
    expect(tester.getRect(_icon).width, moreOrLessEquals(100, epsilon: 0.01));
    expect(_opacityOf(tester, _flash), 0.0);
    for (final word in [
      find.text('New moon!'),
      find.text("You're level 4."),
      _recap,
      find.text('Nice!'),
    ]) {
      expect(_opacityOf(tester, word), 1.0, reason: '$word has risen');
    }
  });

  testWidgets('for a new star, the star pops in straight away, on its own',
      (tester) async {
    await _pumpPopUp(tester, _newStar);

    await tester.pump(const Duration(milliseconds: 450));
    expect(_smaller(0), findsNothing);
    expect(_opacityOf(tester, _icon), 1.0);

    await tester.pump(const Duration(milliseconds: 750));
    expect(tester.getRect(_icon).width, moreOrLessEquals(100, epsilon: 0.01));
    for (final word in [
      find.text('New star!'),
      find.text("You're level 5."),
      find.text('Nice!'),
    ]) {
      expect(_opacityOf(tester, word), 1.0, reason: '$word has risen');
    }
  });

  testWidgets(
      'once settled, the sunburst turns, the halo breathes, the icon bobs and '
      'the sparkles twinkle, until it closes', (tester) async {
    final closed = await _open(tester, _newMoon);

    await tester.pump(const Duration(milliseconds: 2400));
    final before = _stillMoving(tester);
    await tester.pump(const Duration(milliseconds: 800));
    final after = _stillMoving(tester);

    expect(after.turns, greaterThan(before.turns));
    expect(after.haloWidth, isNot(moreOrLessEquals(before.haloWidth)));
    expect(after.iconTop, isNot(moreOrLessEquals(before.iconTop)));
    expect(after.sparkles, isNot(before.sparkles));

    // pumpAndSettle returns only once nothing moves: the clock stops with
    // the pop-up.
    await tester.tap(find.text('Nice!'));
    await tester.pumpAndSettle();
    expect(closed(), 1);
    expect(find.byType(NewLevelPopUpOrganism), findsNothing);
  });

  testWidgets(
      'with reduced motion it shows the finished card at once, with nothing '
      'running', (tester) async {
    await _pumpPopUp(tester, _newMoon, reduceMotion: true);

    for (final part in [
      find.text('New moon!'),
      find.text("You're level 4."),
      _recap,
      find.text('Nice!'),
      _icon,
      find.byType(SunburstAtom),
      _halo,
      for (var k = 0; k < 6; k++) _sparkle(k),
    ]) {
      expect(_opacityOf(tester, part), 1.0, reason: '$part is shown');
    }
    expect(tester.getRect(_icon).width, moreOrLessEquals(100, epsilon: 0.01));
    expect(tester.getRect(_icon).height, moreOrLessEquals(100, epsilon: 0.01));
    for (var i = 0; i < 4; i++) {
      expect(_opacityOf(tester, _smaller(i)), 0.0);
    }
    expect(_opacityOf(tester, _flash), 0.0);

    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'nothing runs');
    expect(tester.widget<SunburstAtom>(find.byType(SunburstAtom)).turns, 0);
  });
}
