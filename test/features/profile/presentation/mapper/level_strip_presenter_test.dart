import 'package:doormer/src/features/profile/presentation/mapper/level_strip_presenter.dart';
import 'package:doormer/src/shared/levels/bloc/level_progress_bloc.dart';
import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:doormer/src/shared/levels/entity/level_progress.dart';
import 'package:flutter_test/flutter_test.dart';

const _level0 = Level(number: 0, suns: 0, moons: 0, stars: 0);
const _level3 = Level(number: 3, suns: 0, moons: 0, stars: 3);
const _level4 = Level(number: 4, suns: 0, moons: 1, stars: 0);
const _level15 = Level(number: 15, suns: 0, moons: 3, stars: 3);
const _level21 = Level(number: 21, suns: 1, moons: 1, stars: 1);

const _star = LevelIcon.star;
const _moon = LevelIcon.moon;
const _sun = LevelIcon.sun;

const _at540 = LevelProgress(
  activeDays: 540,
  level: _level21,
  activeDaysToNextLevel: 32,
  nextLevelIcon: _star,
);

void main() {
  for (final (activeDays, level, toNextLevel, nextIcon, line) in [
    (0, _level0, 5, _star, '0 active days · 5 to your next star'),
    (1, _level0, 4, _star, '1 active day · 4 to your next star'),
    (3, _level0, 2, _star, '3 active days · 2 to your next star'),
    (37, _level4, 8, _star, '37 active days · 8 to your next star'),
    (31, _level3, 1, _moon, '31 active days · 1 to your next moon'),
    (319, _level15, 1, _sun, '319 active days · 1 to your next sun'),
    (540, _level21, 32, _star, '540 active days · 32 to your next star'),
  ]) {
    test('reads "$line" at $activeDays active days', () {
      final progress = LevelProgress(
        activeDays: activeDays,
        level: level,
        activeDaysToNextLevel: toNextLevel,
        nextLevelIcon: nextIcon,
      );

      expect(LevelStripPresenter.activeDaysLine(progress), line);
    });
  }

  test('the strip names the level, draws it, and opens How levels work', () {
    var explained = 0;

    final strip = LevelStripPresenter.stripFor(
      const LevelProgressState(_at540),
      onExplain: () => explained++,
    )!;
    strip.onExplain();

    expect(strip.title, 'Level 21');
    expect(strip.level, _level21);
    expect(strip.activeDaysLine, '540 active days · 32 to your next star');
    expect(explained, 1);
  });

  test('at level 0 the title is "Level 0"', () {
    final strip = LevelStripPresenter.stripFor(
      const LevelProgressState(LevelProgress(
        activeDays: 1,
        level: _level0,
        activeDaysToNextLevel: 4,
        nextLevelIcon: _star,
      )),
      onExplain: () {},
    )!;

    expect(strip.title, 'Level 0');
  });

  test('there is no strip before a count of the day brings the progress', () {
    expect(
      LevelStripPresenter.stripFor(
        const LevelProgressState(null),
        onExplain: () {},
      ),
      isNull,
    );
  });
}
