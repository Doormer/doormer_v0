import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:flutter/foundation.dart';

/// The student's own level, on Profile's level card.
class LevelCardParams {
  /// Drawn as icons. Level 0 has none, and shows a faded star instead.
  final Level level;

  /// What screen readers hear for the icons, such as `Level 21`. It isn't
  /// shown: the icons say it, and the days to the next star hint at them.
  final String levelLabel;

  /// How much of this level's days are done, from 0 to 1: how full the bar
  /// is.
  final double barFill;

  /// The icon the next level adds, faded at the bar's end.
  final LevelIcon nextLevelIcon;

  /// Under the bar on the left, such as `548 active days`.
  final String activeDaysLabel;

  /// Under the bar on the right, in gold, such as `24 days`.
  final String daysToGoLabel;

  /// After [daysToGoLabel]: `to your next star`, `to your next moon` or
  /// `to your next sun`.
  final String toNextIconLabel;

  /// Opens How levels work.
  final VoidCallback onExplain;

  const LevelCardParams({
    required this.level,
    required this.levelLabel,
    required this.barFill,
    required this.nextLevelIcon,
    required this.activeDaysLabel,
    required this.daysToGoLabel,
    required this.toNextIconLabel,
    required this.onExplain,
  });
}
