import 'package:doormer/src/shared/levels/level_labels.dart';

import '../bloc/active_day_bloc.dart';

/// The toast that celebrates a new level, the only time levels speak up.
/// Pure: only the nav bar shell calls it.
abstract final class LevelUpPresenter {
  /// "New moon! You're level 4.", for a count that raised the level. Null
  /// for any other state, which says nothing.
  static String? toastFor(ActiveDayState state) {
    if (state is! ActiveDayCounted || !state.outcome.raisedLevel) return null;
    final newIcon = state.outcome.newIcon!;
    final level = state.outcome.progress.level.number;
    return "New ${LevelLabels.iconName(newIcon)}! You're level $level.";
  }
}
