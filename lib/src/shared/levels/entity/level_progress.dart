import 'package:equatable/equatable.dart';

import 'level.dart';
import 'level_icon.dart';

/// The signed-in student's active days, the level they reach, and what the
/// next level takes. Only the student sees it: friends see a level's icons.
class LevelProgress extends Equatable {
  /// The days, in New Zealand time, on which the student opened Doormer
  /// signed in. Each counts once.
  final int activeDays;

  final Level level;

  /// How many more active days the next level takes.
  final int activeDaysToNextLevel;

  /// The icon the next level adds.
  final LevelIcon nextLevelIcon;

  const LevelProgress({
    required this.activeDays,
    required this.level,
    required this.activeDaysToNextLevel,
    required this.nextLevelIcon,
  });

  @override
  List<Object?> get props =>
      [activeDays, level, activeDaysToNextLevel, nextLevelIcon];
}
