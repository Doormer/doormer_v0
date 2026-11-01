import 'package:doormer/src/features/levels/domain/entity/active_day_outcome.dart';
import 'package:doormer/src/features/levels/presentation/bloc/active_day_bloc.dart';
import 'package:doormer/src/features/levels/presentation/mapper/level_up_presenter.dart';
import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:doormer/src/shared/levels/entity/level_progress.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_levels_repository.dart';

/// The 45th active day: a new star, level 5.
const _newStarAt45 = ActiveDayOutcome(
  counted: true,
  newIcon: LevelIcon.star,
  progress: LevelProgress(
    activeDays: 45,
    level: Level(number: 5, suns: 0, moons: 1, stars: 1),
    activeDaysToNextLevel: 15,
    nextLevelIcon: LevelIcon.star,
  ),
);

/// The 320th active day: a new sun, level 16.
const _newSunAt320 = ActiveDayOutcome(
  counted: true,
  newIcon: LevelIcon.sun,
  progress: LevelProgress(
    activeDays: 320,
    level: Level(number: 16, suns: 1, moons: 0, stars: 0),
    activeDaysToNextLevel: 37,
    nextLevelIcon: LevelIcon.star,
  ),
);

void main() {
  for (final (name, outcome, toast) in [
    ('a new star', _newStarAt45, "New star! You're level 5."),
    ('a new moon', newMoonAt32, "New moon! You're level 4."),
    ('a new sun', _newSunAt320, "New sun! You're level 16."),
  ]) {
    test('celebrates $name with the level the progress names', () {
      expect(LevelUpPresenter.toastFor(ActiveDayCounted(outcome)), toast);
    });
  }

  test('says nothing for a count that raised no level', () {
    expect(
      LevelUpPresenter.toastFor(const ActiveDayCounted(alreadyCountedAt32)),
      isNull,
    );
  });

  test('says nothing before a count, during one, or when one fails', () {
    for (final state in const [
      ActiveDayNotCounted(),
      ActiveDayCounting(),
      ActiveDayError("We couldn't count today as an active day."),
    ]) {
      expect(LevelUpPresenter.toastFor(state), isNull, reason: '$state');
    }
  });
}
