import '../entity/level_icon.dart';
import '../entity/level_progress.dart';
import 'level_icon_model.dart';
import 'level_model.dart';

/// The API's `LevelProgress`:
/// `{active_days, level, active_days_to_next_level, next_level_icon}`.
class LevelProgressModel {
  final int activeDays;
  final LevelModel level;
  final int activeDaysToNextLevel;
  final LevelIcon nextLevelIcon;

  const LevelProgressModel({
    required this.activeDays,
    required this.level,
    required this.activeDaysToNextLevel,
    required this.nextLevelIcon,
  });

  /// Throws when a field is missing or has the wrong type, or names an icon
  /// the app doesn't know.
  factory LevelProgressModel.fromJson(Map<String, dynamic> json) =>
      LevelProgressModel(
        activeDays: json['active_days'] as int,
        level: LevelModel.fromJson(json['level'] as Map<String, dynamic>),
        activeDaysToNextLevel: json['active_days_to_next_level'] as int,
        nextLevelIcon: LevelIconModel.fromJson(json['next_level_icon']),
      );

  LevelProgress toEntity() => LevelProgress(
        activeDays: activeDays,
        level: level.toEntity(),
        activeDaysToNextLevel: activeDaysToNextLevel,
        nextLevelIcon: nextLevelIcon,
      );
}
