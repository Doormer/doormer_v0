import 'entity/level.dart';
import 'entity/level_icon.dart';

/// What the app calls a level and its icons, wherever it shows one or reads
/// one out. Friends never see a level's number: only screen readers say it.
abstract final class LevelLabels {
  /// `star`, `moon` or `sun`.
  static String iconName(LevelIcon icon) => switch (icon) {
        LevelIcon.star => 'star',
        LevelIcon.moon => 'moon',
        LevelIcon.sun => 'sun',
      };

  /// `Level 21`: the heading of the student's own level strip, and what
  /// screen readers hear for a friend's icons.
  static String levelOf(Level level) => 'Level ${level.number}';

  /// `Sam, level 6`: what screen readers hear for a friend's nickname and
  /// the icons after it. The nickname alone when there is no level.
  static String nicknameWithLevel(String nickname, Level? level) =>
      level == null ? nickname : '$nickname, level ${level.number}';
}
