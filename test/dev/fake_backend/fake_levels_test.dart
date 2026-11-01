import 'package:doormer/src/dev/fake_backend/fake_levels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('level N takes N² + 4N active days', () {
    for (final (activeDays, level) in [
      (0, 0),
      (4, 0),
      (5, 1),
      (11, 1),
      (12, 2),
      (21, 3),
      (31, 3),
      (32, 4),
      (37, 4),
      (60, 6),
      (319, 15),
      (320, 16),
      (525, 21),
      (540, 21),
    ]) {
      expect(fakeLevelFor(activeDays), level, reason: '$activeDays days');
    }
  });

  test('draws 16 levels as a sun, 4 as a moon and 1 as a star', () {
    expect(
        fakeLevelJson(21), {'number': 21, 'suns': 1, 'moons': 1, 'stars': 1});
    expect(fakeLevelJson(6), {'number': 6, 'suns': 0, 'moons': 1, 'stars': 2});
    expect(
        fakeLevelJson(64), {'number': 64, 'suns': 4, 'moons': 0, 'stars': 0});
  });

  test('a new level adds a star if it has stars, else a moon, else a sun', () {
    expect(fakeNewestIconOf(0), isNull);
    expect(fakeNewestIconOf(3), 'star');
    expect(fakeNewestIconOf(4), 'moon');
    expect(fakeNewestIconOf(15), 'star');
    expect(fakeNewestIconOf(16), 'sun');
    expect(fakeNewestIconOf(21), 'star');
  });

  test('progress says how far the next level is, and what it adds', () {
    expect(fakeLevelProgressJson(37), {
      'active_days': 37,
      'level': {'number': 4, 'suns': 0, 'moons': 1, 'stars': 0},
      'active_days_to_next_level': 8,
      'next_level_icon': 'star',
    });
    expect(fakeLevelProgressJson(540)['active_days_to_next_level'], 32);
    expect(fakeLevelProgressJson(31)['next_level_icon'], 'moon');
    expect(fakeLevelProgressJson(319)['next_level_icon'], 'sun');
  });
}
