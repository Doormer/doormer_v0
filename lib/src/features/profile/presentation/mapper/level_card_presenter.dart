import 'package:doormer/src/shared/levels/bloc/level_progress_bloc.dart';
import 'package:doormer/src/shared/levels/entity/level_progress.dart';
import 'package:doormer/src/shared/levels/level_labels.dart';
import 'package:flutter/foundation.dart';

import '../params/level_card_params.dart';

/// The words and the bar on Profile's level card. Pure: only the page calls
/// it.
abstract final class LevelCardPresenter {
  /// The card for the student's progress, or null when a count of the day
  /// hasn't brought any yet: Profile then shows no card.
  static LevelCardParams? cardFor(
    LevelProgressState state, {
    required VoidCallback onExplain,
  }) {
    final progress = state.progress;
    if (progress == null) return null;
    final nextIcon = LevelLabels.iconName(progress.nextLevelIcon);
    return LevelCardParams(
      level: progress.level,
      title: LevelLabels.levelOf(progress.level),
      barFill: barFillOf(progress),
      nextLevelIcon: progress.nextLevelIcon,
      activeDaysLabel: activeDaysLabelOf(progress.activeDays),
      daysToGoLabel: daysToGoLabelOf(progress.activeDaysToNextLevel),
      nextLevelLabel: 'to your next $nextIcon',
      onExplain: onExplain,
    );
  }

  /// How much of this level's days are done: 0 on its first day, and just
  /// under 1 on its last.
  ///
  /// Level N starts on active day N² + 4N, and the next level on the day
  /// the progress names: today's active days plus the days still to go.
  static double barFillOf(LevelProgress progress) {
    final number = progress.level.number;
    final firstDay = number * number + 4 * number;
    final nextFirstDay = progress.activeDays + progress.activeDaysToNextLevel;
    final days = nextFirstDay - firstDay;
    if (days <= 0) return 0;
    return ((progress.activeDays - firstDay) / days).clamp(0.0, 1.0);
  }

  /// `548 active days`, and `1 active day`.
  static String activeDaysLabelOf(int activeDays) =>
      activeDays == 1 ? '1 active day' : '$activeDays active days';

  /// `24 days`, and `1 day`.
  static String daysToGoLabelOf(int days) => days == 1 ? '1 day' : '$days days';
}
