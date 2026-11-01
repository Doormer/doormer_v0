import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:doormer/src/shared/levels/level_labels.dart';
import 'package:flutter_test/flutter_test.dart';

const _level6 = Level(number: 6, suns: 0, moons: 1, stars: 2);

void main() {
  test('names each icon', () {
    expect(LevelLabels.iconName(LevelIcon.star), 'star');
    expect(LevelLabels.iconName(LevelIcon.moon), 'moon');
    expect(LevelLabels.iconName(LevelIcon.sun), 'sun');
  });

  test('a level is "Level" and its number, level 0 included', () {
    expect(LevelLabels.levelOf(_level6), 'Level 6');
    expect(
      LevelLabels.levelOf(const Level(number: 0, suns: 0, moons: 0, stars: 0)),
      'Level 0',
    );
  });

  test("a friend's nickname comes with their level, or alone without one", () {
    expect(LevelLabels.nicknameWithLevel('Sam', _level6), 'Sam, level 6');
    expect(LevelLabels.nicknameWithLevel('Alex', null), 'Alex');
  });
}
