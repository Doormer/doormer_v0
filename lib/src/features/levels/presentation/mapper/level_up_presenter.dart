import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:doormer/src/shared/levels/level_labels.dart';

import '../bloc/active_day_bloc.dart';
import '../params/new_level_pop_up_params.dart';

/// The pop-up that celebrates a new level, the only time levels speak up.
/// Pure: only the nav bar shell calls it.
abstract final class LevelUpPresenter {
  /// The pop-up for a count that raised the level: "New moon!" and
  /// "You're level 4.", with the four stars that made the moon. Null for any
  /// other state, which says nothing.
  static NewLevelPopUpParams? popUpFor(ActiveDayState state) {
    if (state is! ActiveDayCounted || !state.outcome.raisedLevel) return null;
    final newIcon = state.outcome.newIcon!;
    final title = 'New ${LevelLabels.iconName(newIcon)}!';
    final levelLine = "You're level ${state.outcome.progress.level.number}.";
    return NewLevelPopUpParams(
      newIcon: newIcon,
      smallerIcon: switch (newIcon) {
        LevelIcon.star => null,
        LevelIcon.moon => LevelIcon.star,
        LevelIcon.sun => LevelIcon.moon,
      },
      title: title,
      levelLine: levelLine,
      announcement: '$title $levelLine',
    );
  }
}
