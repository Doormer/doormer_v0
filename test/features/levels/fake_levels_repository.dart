import 'dart:async';

import 'package:doormer/src/features/levels/domain/entity/active_day_outcome.dart';
import 'package:doormer/src/features/levels/domain/repository/levels_repository.dart';
import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:doormer/src/shared/levels/entity/level_progress.dart';

const level4 = Level(number: 4, suns: 0, moons: 1, stars: 0);

/// The 32nd active day: a new moon, level 4, 13 days from a star.
const newMoonAt32 = ActiveDayOutcome(
  counted: true,
  newIcon: LevelIcon.moon,
  progress: LevelProgress(
    activeDays: 32,
    level: level4,
    activeDaysToNextLevel: 13,
    nextLevelIcon: LevelIcon.star,
  ),
);

/// The same day, counted again: nothing changes.
const alreadyCountedAt32 = ActiveDayOutcome(
  counted: false,
  progress: LevelProgress(
    activeDays: 32,
    level: level4,
    activeDaysToNextLevel: 13,
    nextLevelIcon: LevelIcon.star,
  ),
);

/// Plays `/levels/active-day` in memory, for the levels feature's tests and
/// the nav bar shell's.
///
/// Each count answers with the next of the outcomes it was made with. Once
/// they run out, a count never answers, which suits a test that isn't about
/// levels: nothing celebrates, and nothing waits on a timer.
class FakeLevelsRepository implements LevelsRepository {
  final List<ActiveDayOutcome> _outcomes;

  /// How many times the app asked to count the day.
  int counts = 0;

  /// What the next count throws instead of answering.
  Object? failNext;

  /// While set, each count waits for it before it answers.
  Completer<void>? hold;

  FakeLevelsRepository([List<ActiveDayOutcome> outcomes = const []])
      : _outcomes = [...outcomes];

  @override
  Future<ActiveDayOutcome> countActiveDay() async {
    counts++;
    final wait = hold;
    if (wait != null) await wait.future;
    final failure = failNext;
    failNext = null;
    if (failure != null) throw failure;
    if (_outcomes.isEmpty) return Completer<ActiveDayOutcome>().future;
    return _outcomes.removeAt(0);
  }
}
