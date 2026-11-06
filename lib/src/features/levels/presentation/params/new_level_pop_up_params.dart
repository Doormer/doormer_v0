import 'package:doormer/src/shared/levels/entity/level_icon.dart';

/// What the pop-up for a new level shows. `LevelUpPresenter.popUpFor`
/// makes it.
class NewLevelPopUpParams {
  /// The icon the new level added, drawn large.
  final LevelIcon newIcon;

  /// The icon four of which make [newIcon]: stars for a moon, moons for a
  /// sun. Four of them merge into it as the pop-up opens, and the recap row
  /// shows the sum. Null for a star, which pops in on its own.
  final LevelIcon? smallerIcon;

  /// Such as `New moon!`.
  final String title;

  /// Such as `You're level 4.`
  final String levelLine;

  /// What screen readers hear as it opens, such as
  /// `New moon! You're level 4.`
  final String announcement;

  const NewLevelPopUpParams({
    required this.newIcon,
    required this.smallerIcon,
    required this.title,
    required this.levelLine,
    required this.announcement,
  });
}
