import 'package:doormer/src/shared/levels/bloc/level_progress_bloc.dart';
import 'package:doormer/src/shared/levels/entity/level_progress.dart';
import 'package:doormer/src/shared/levels/level_labels.dart';
import 'package:flutter/foundation.dart';

import '../params/level_strip_params.dart';

/// The words on Profile's level strip. Pure: only the page calls it.
abstract final class LevelStripPresenter {
  /// The strip for the student's progress, or null when a count of the day
  /// hasn't brought any yet: Profile then shows no strip.
  static LevelStripParams? stripFor(
    LevelProgressState state, {
    required VoidCallback onExplain,
  }) {
    final progress = state.progress;
    if (progress == null) return null;
    return LevelStripParams(
      level: progress.level,
      title: LevelLabels.levelOf(progress.level),
      activeDaysLine: activeDaysLine(progress),
      onExplain: onExplain,
    );
  }

  /// `540 active days · 32 to your next star`, and `1 active day` for one.
  static String activeDaysLine(LevelProgress progress) {
    final days = progress.activeDays;
    final unit = days == 1 ? 'active day' : 'active days';
    final nextIcon = LevelLabels.iconName(progress.nextLevelIcon);
    return '$days $unit · ${progress.activeDaysToNextLevel} to your next '
        '$nextIcon';
  }
}
