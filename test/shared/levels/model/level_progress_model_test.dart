import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:doormer/src/shared/levels/entity/level_progress.dart';
import 'package:doormer/src/shared/levels/model/level_progress_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// The API's progress for 540 active days: level 21, 32 days from a star.
Map<String, dynamic> _progressJson({Object? nextLevelIcon = 'star'}) => {
      'active_days': 540,
      'level': {'number': 21, 'suns': 1, 'moons': 1, 'stars': 1},
      'active_days_to_next_level': 32,
      'next_level_icon': nextLevelIcon,
    };

void main() {
  test('reads the active days, the level and what the next level takes', () {
    expect(
      LevelProgressModel.fromJson(_progressJson()).toEntity(),
      const LevelProgress(
        activeDays: 540,
        level: Level(number: 21, suns: 1, moons: 1, stars: 1),
        activeDaysToNextLevel: 32,
        nextLevelIcon: LevelIcon.star,
      ),
    );
  });

  test('reads each icon the next level can add', () {
    for (final (name, icon) in [
      ('star', LevelIcon.star),
      ('moon', LevelIcon.moon),
      ('sun', LevelIcon.sun),
    ]) {
      expect(
        LevelProgressModel.fromJson(_progressJson(nextLevelIcon: name))
            .nextLevelIcon,
        icon,
        reason: name,
      );
    }
  });

  test('an icon the app does not know cannot be read', () {
    expect(
      () => LevelProgressModel.fromJson(_progressJson(nextLevelIcon: 'crown')),
      throwsFormatException,
    );
  });

  test('progress with no level cannot be read', () {
    expect(
      () => LevelProgressModel.fromJson({..._progressJson()}..remove('level')),
      throwsA(isA<TypeError>()),
    );
  });
}
