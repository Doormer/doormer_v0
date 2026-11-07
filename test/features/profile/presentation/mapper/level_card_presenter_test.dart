import 'package:doormer/src/features/profile/presentation/mapper/level_card_presenter.dart';
import 'package:doormer/src/shared/levels/bloc/level_progress_bloc.dart';
import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:doormer/src/shared/levels/entity/level_progress.dart';
import 'package:flutter_test/flutter_test.dart';

const _level0 = Level(number: 0, suns: 0, moons: 0, stars: 0);
const _level3 = Level(number: 3, suns: 0, moons: 0, stars: 3);
const _level15 = Level(number: 15, suns: 0, moons: 3, stars: 3);
const _level21 = Level(number: 21, suns: 1, moons: 1, stars: 1);

/// [activeDays] at [level], [toNextLevel] days from the next level, which
/// adds [nextIcon].
LevelProgress _progress(
  int activeDays,
  Level level,
  int toNextLevel, [
  LevelIcon nextIcon = LevelIcon.star,
]) =>
    LevelProgress(
      activeDays: activeDays,
      level: level,
      activeDaysToNextLevel: toNextLevel,
      nextLevelIcon: nextIcon,
    );

void main() {
  group('the bar fills with the share of the level done', () {
    // Level N starts on active day N² + 4N: level 21 on day 525, and level
    // 22 on day 572, 47 days later.
    for (final (name, progress, fill) in [
      ("empty on level 21's first day", _progress(525, _level21, 47), 0.0),
      (
        'just under half full at 548 active days, 24 from level 22',
        _progress(548, _level21, 24),
        23 / 47,
      ),
      (
        "all but full on level 21's last day",
        _progress(571, _level21, 1),
        46 / 47,
      ),
      ('empty at no active days', _progress(0, _level0, 5), 0.0),
      (
        'a fifth full at level 0 after one active day',
        _progress(1, _level0, 4),
        0.2,
      ),
      (
        "empty, not broken, when the days to go don't add up",
        _progress(525, _level21, 0),
        0.0,
      ),
    ]) {
      test(name, () {
        expect(LevelCardPresenter.barFillOf(progress), moreOrLessEquals(fill));
      });
    }
  });

  for (final (days, label) in [
    (0, '0 active days'),
    (1, '1 active day'),
    (548, '548 active days'),
  ]) {
    test('$days active days read "$label"', () {
      expect(LevelCardPresenter.activeDaysLabelOf(days), label);
    });
  }

  for (final (days, label) in [(1, '1 day'), (24, '24 days')]) {
    test('$days days to go read "$label"', () {
      expect(LevelCardPresenter.daysToGoLabelOf(days), label);
    });
  }

  test('the card names the level, fills the bar and says what comes next', () {
    var explained = 0;

    final card = LevelCardPresenter.cardFor(
      LevelProgressState(_progress(548, _level21, 24)),
      onExplain: () => explained++,
    )!;
    card.onExplain();

    expect(card.levelLabel, 'Level 21');
    expect(card.level, _level21);
    expect(card.barFill, moreOrLessEquals(23 / 47));
    expect(card.nextLevelIcon, LevelIcon.star);
    expect(card.activeDaysLabel, '548 active days');
    expect(card.daysToGoLabel, '24 days');
    expect(card.toNextIconLabel, 'to your next star');
    expect(explained, 1);
  });

  for (final (progress, toNextIconLabel) in [
    (_progress(31, _level3, 1, LevelIcon.moon), 'to your next moon'),
    (_progress(319, _level15, 1, LevelIcon.sun), 'to your next sun'),
  ]) {
    test('one day before a new ${progress.nextLevelIcon.name}', () {
      final card = LevelCardPresenter.cardFor(
        LevelProgressState(progress),
        onExplain: () {},
      )!;

      expect(card.daysToGoLabel, '1 day');
      expect(card.toNextIconLabel, toNextIconLabel);
      expect(card.nextLevelIcon, progress.nextLevelIcon);
    });
  }

  test('at level 0 the title is "Level 0"', () {
    final card = LevelCardPresenter.cardFor(
      LevelProgressState(_progress(1, _level0, 4)),
      onExplain: () {},
    )!;

    expect(card.levelLabel, 'Level 0');
    expect(card.level, _level0);
  });

  test('there is no card before a count of the day brings the progress', () {
    expect(
      LevelCardPresenter.cardFor(
        const LevelProgressState(null),
        onExplain: () {},
      ),
      isNull,
    );
  });
}
