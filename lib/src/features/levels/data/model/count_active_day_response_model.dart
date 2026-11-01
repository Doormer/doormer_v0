import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:doormer/src/shared/levels/model/level_icon_model.dart';
import 'package:doormer/src/shared/levels/model/level_progress_model.dart';

import '../../domain/entity/active_day_outcome.dart';

/// The API's `CountActiveDayResp`: `{counted, new_icon?, progress}`.
class CountActiveDayResponseModel {
  final bool counted;

  /// Null unless today raised the level.
  final LevelIcon? newIcon;

  final LevelProgressModel progress;

  const CountActiveDayResponseModel({
    required this.counted,
    required this.newIcon,
    required this.progress,
  });

  /// Throws when a field is missing or has the wrong type, or names an icon
  /// the app doesn't know. The data source reports that as an answer it
  /// cannot read.
  factory CountActiveDayResponseModel.fromJson(Map<String, dynamic> json) {
    final newIcon = json['new_icon'];
    return CountActiveDayResponseModel(
      counted: json['counted'] as bool,
      newIcon: newIcon == null ? null : LevelIconModel.fromJson(newIcon),
      progress: LevelProgressModel.fromJson(
        json['progress'] as Map<String, dynamic>,
      ),
    );
  }

  ActiveDayOutcome toEntity() => ActiveDayOutcome(
        counted: counted,
        newIcon: newIcon,
        progress: progress.toEntity(),
      );
}
