// Levels as `taka-api` works them out: level N needs N² + 4N active days,
// and a sun is 16 levels, a moon 4 and a star 1.

/// The level [activeDays] reach: the highest N whose N² + 4N they reach.
int fakeLevelFor(int activeDays) {
  var level = 0;
  while (_activeDaysFor(level + 1) <= activeDays) {
    level++;
  }
  return level;
}

/// The API's `Level` for [level].
Map<String, Object?> fakeLevelJson(int level) => {
      'number': level,
      'suns': level ~/ 16,
      'moons': (level % 16) ~/ 4,
      'stars': level % 4,
    };

/// The API's `LevelProgress` for [activeDays].
Map<String, Object?> fakeLevelProgressJson(int activeDays) {
  final level = fakeLevelFor(activeDays);
  return {
    'active_days': activeDays,
    'level': fakeLevelJson(level),
    'active_days_to_next_level': _activeDaysFor(level + 1) - activeDays,
    'next_level_icon': fakeNewestIconOf(level + 1),
  };
}

/// The icon that reaching [level] added: a star if it has stars, else a
/// moon if it has moons, else a sun. Null at level 0, which has none.
String? fakeNewestIconOf(int level) {
  if (level == 0) return null;
  if (level % 4 > 0) return 'star';
  if ((level % 16) ~/ 4 > 0) return 'moon';
  return 'sun';
}

int _activeDaysFor(int level) => level * level + 4 * level;
