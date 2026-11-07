import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/profile/presentation/atoms/gold_panel_atom.dart';
import 'package:doormer/src/features/profile/presentation/molecules/level_progress_bar_molecule.dart';
import 'package:doormer/src/features/profile/presentation/organisms/level_card_organism.dart';
import 'package:doormer/src/features/profile/presentation/params/level_card_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/level_icons_atom.dart';
import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _level21 = Level(number: 21, suns: 1, moons: 1, stars: 1);
const _toNextStar = '24 days to your next star';

/// Loads the app's faces, so words take the room they take in the app
/// rather than the test font's 1 em a letter.
Future<void> _loadFaces() async {
  final display = FontLoader(kDisplayFont)
    ..addFont(rootBundle.load('assets/fonts/Fredoka-700.ttf'));
  final body = FontLoader(kBodyFont);
  for (final weight in [400, 600]) {
    body.addFont(rootBundle.load('assets/fonts/SpaceGrotesk-$weight.ttf'));
  }
  await Future.wait([display.load(), body.load()]);
}

/// The card on the 360 by 690 design phone, 20 in from each side, as
/// Profile places it, or [width] wide when given.
Future<void> _pump(
  WidgetTester tester,
  LevelCardParams params, {
  double? width,
  bool framed = true,
}) async {
  tester.view.physicalSize = const Size(360, 690);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: LevelCardOrganism(params: params, framed: framed),
            ),
          ),
        ),
      ),
    ),
  ));
}

/// Level 21 at 548 active days, 24 from a star, unless told otherwise.
LevelCardParams _card({
  Level level = _level21,
  String title = 'Level 21',
  double barFill = 23 / 47,
  String activeDaysLabel = '548 active days',
  String daysToGoLabel = '24 days',
  VoidCallback? onExplain,
}) =>
    LevelCardParams(
      level: level,
      title: title,
      barFill: barFill,
      nextLevelIcon: LevelIcon.star,
      activeDaysLabel: activeDaysLabel,
      daysToGoLabel: daysToGoLabel,
      toNextIconLabel: 'to your next star',
      onExplain: onExplain ?? () {},
    );

void main() {
  setUpAll(_loadFaces);

  testWidgets('shows the icons at 30, then the level, with ⓘ at the right',
      (tester) async {
    await _pump(tester, _card());

    final icons = find.byType(LevelIconsAtom);
    final drawn = tester.widget<LevelIconsAtom>(icons);
    expect((drawn.suns, drawn.moons, drawn.stars), (1, 1, 1));
    expect(drawn.size, 30);
    final title = tester.getRect(find.text('Level 21'));
    final info = tester.getRect(find.byTooltip('How levels work'));
    final card = tester.getRect(find.byType(LevelCardOrganism));
    expect(tester.getRect(icons).right, lessThanOrEqualTo(title.left));
    expect(info.left, greaterThanOrEqualTo(title.right));
    expect(card.right - info.right, lessThanOrEqualTo(8),
        reason: 'at the right of the card');
  });

  testWidgets(
      "shows how far through the level the student is, and the next level's "
      'icon, under the title', (tester) async {
    await _pump(tester, _card());

    final bar = find.byType(LevelProgressBarMolecule);
    expect(tester.widget<LevelProgressBarMolecule>(bar).fill, 23 / 47);
    expect(tester.widget<LevelProgressBarMolecule>(bar).nextLevelIcon,
        LevelIcon.star);
    expect(tester.getRect(bar).top,
        greaterThan(tester.getRect(find.text('Level 21')).bottom));
  });

  testWidgets(
      'puts the active days on the left and the days to go on the right, '
      'those in gold', (tester) async {
    await _pump(tester, _card());

    final bar = tester.getRect(find.byType(LevelProgressBarMolecule));
    final activeDays = tester.getRect(find.text('548 active days'));
    final toNextStar = tester.getRect(find.text(_toNextStar));
    expect(activeDays.top, greaterThan(bar.bottom));
    expect(activeDays.left, moreOrLessEquals(bar.left));
    expect(toNextStar.right, moreOrLessEquals(bar.right));
    expect(toNextStar.top, moreOrLessEquals(activeDays.top),
        reason: 'on one line');
    final spans =
        (tester.widget<Text>(find.text(_toNextStar)).textSpan! as TextSpan)
            .children!;
    final daysToGo = spans.first as TextSpan;
    expect(daysToGo.text, '24 days');
    expect(daysToGo.style?.color, QuestPalette.levelPaleGold);
    expect(daysToGo.style?.fontWeight, FontWeight.w600);
  });

  for (final scale in [1.5, 2.0]) {
    testWidgets(
        'with text at $scale×, the days to go drop under the active days, '
        'starting at the left, and the card still fits', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(tester, _card());

      final bar = tester.getRect(find.byType(LevelProgressBarMolecule));
      final activeDays = tester.getRect(find.text('548 active days'));
      final toNextStar = find.text(_toNextStar);
      expect(tester.getRect(toNextStar).top,
          greaterThanOrEqualTo(activeDays.bottom));
      // Where the words start, not their box, which fills the line once
      // they wrap.
      final words = tester.renderObject<RenderParagraph>(toNextStar);
      final firstLetter = words
          .getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 1))
          .first;
      expect(words.localToGlobal(Offset(firstLetter.left, 0)).dx,
          moreOrLessEquals(bar.left, epsilon: 0.5));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'at level 0 shows "Level 0" with no icons, and the bar filling toward '
      'a star', (tester) async {
    await _pump(
      tester,
      _card(
        level: const Level(number: 0, suns: 0, moons: 0, stars: 0),
        title: 'Level 0',
        barFill: 0.2,
        activeDaysLabel: '1 active day',
        daysToGoLabel: '4 days',
      ),
    );

    expect(find.byType(LevelIconsAtom), findsNothing);
    expect(find.text('Level 0'), findsOneWidget);
    expect(find.text('1 active day'), findsOneWidget);
    expect(find.text('4 days to your next star'), findsOneWidget);
    expect(
      tester
          .widget<LevelProgressBarMolecule>(
              find.byType(LevelProgressBarMolecule))
          .fill,
      0.2,
    );
  });

  testWidgets(
      'a long row of icons shrinks to fit, so the level and ⓘ stay whole',
      (tester) async {
    // Level 47: two suns, three moons and three stars.
    await _pump(
      tester,
      _card(
        level: const Level(number: 47, suns: 2, moons: 3, stars: 3),
        title: 'Level 47',
      ),
    );

    final icons = tester.getRect(find.byType(LevelIconsAtom));
    final title = tester.getRect(find.text('Level 47'));
    final info = tester.getRect(find.byTooltip('How levels work'));
    final card = tester.getRect(find.byType(LevelCardOrganism));
    expect(icons.width, lessThan(8 * 30), reason: 'drawn smaller than 30');
    expect(
        title.width,
        moreOrLessEquals(
            tester.renderObject<RenderBox>(find.text('Level 47')).size.width),
        reason: 'the title keeps its size: the icons give way');
    expect(icons.right, lessThanOrEqualTo(title.left));
    expect(title.right, lessThanOrEqualTo(info.left));
    expect(info.right, lessThanOrEqualTo(card.right));
  });

  testWidgets(
      'in a narrow card with big text, as half of a wide Profile can be, the '
      'title shrinks to fit rather than running under ⓘ', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester, _card(), width: 200);

    expect(tester.takeException(), isNull);
    final title = tester.getRect(find.text('Level 21'));
    final info = tester.getRect(find.byTooltip('How levels work'));
    expect(title.right, lessThanOrEqualTo(info.left));
  });

  testWidgets(
      'ⓘ is 48 square, big enough to tap on a phone, and the content still '
      'sits 16 in from the edges, with the bar 14 under the icons',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _card());

    expect(
        tester.getSize(find.byTooltip('How levels work')), const Size(48, 48));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    final card = tester.getRect(find.byType(LevelCardOrganism));
    final icons = tester.getRect(find.byType(LevelIconsAtom));
    final info = tester.getRect(find.byIcon(Icons.info_outline_rounded));
    final bar = tester.getRect(find.byType(LevelProgressBarMolecule));
    // 16 in, plus the card's 1 px border.
    expect(icons.left - card.left, moreOrLessEquals(17));
    expect(icons.top - card.top, moreOrLessEquals(17));
    expect(card.right - info.right, moreOrLessEquals(17));
    expect(card.right - bar.right, moreOrLessEquals(17));
    expect(bar.top - icons.bottom, moreOrLessEquals(14));
    semantics.dispose();
  });

  testWidgets(
      'draws its own gold panel, or none when it shares one, as beside the '
      'header on a wide Profile', (tester) async {
    await _pump(tester, _card());
    expect(find.byType(GoldPanelAtom), findsOneWidget);

    await _pump(tester, _card(), framed: false);
    expect(find.byType(GoldPanelAtom), findsNothing);
    expect(find.text('Level 21'), findsOneWidget);
  });

  testWidgets('ⓘ opens How levels work', (tester) async {
    var explained = 0;
    await _pump(tester, _card(onExplain: () => explained++));

    await tester.tap(find.byTooltip('How levels work'));

    expect(explained, 1);
  });
}
