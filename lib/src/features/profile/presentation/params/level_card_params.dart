import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:flutter/foundation.dart';

/// The student's own level, on Profile's level card.
class LevelCardParams {
  /// Drawn as icons before [title]. Level 0 has none.
  final Level level;

  /// Such as `Level 21`.
  final String title;

  /// How much of this level's days are done, from 0 to 1: how full the bar
  /// is.
  final double barFill;

  /// The icon the next level adds, faded at the bar's end.
  final LevelIcon nextLevelIcon;

  /// Under the bar on the left, such as `548 active days`.
  final String activeDaysLabel;

  /// Under the bar on the right, in gold, such as `24 days`.
  final String daysToGoLabel;

  /// After [daysToGoLabel], such as `to your next star`.
  final String nextLevelLabel;

  /// Opens How levels work.
  final VoidCallback onExplain;

  const LevelCardParams({
    required this.level,
    required this.title,
    required this.barFill,
    required this.nextLevelIcon,
    required this.activeDaysLabel,
    required this.daysToGoLabel,
    required this.nextLevelLabel,
    required this.onExplain,
  });
}
