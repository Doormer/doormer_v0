import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/shared/levels/bloc/level_progress_bloc.dart';
import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:doormer/src/shared/levels/entity/level_progress.dart';
import 'package:flutter_test/flutter_test.dart';

const _level4 = Level(number: 4, suns: 0, moons: 1, stars: 0);

const _at32 = LevelProgress(
  activeDays: 32,
  level: _level4,
  activeDaysToNextLevel: 13,
  nextLevelIcon: LevelIcon.star,
);

const _at33 = LevelProgress(
  activeDays: 33,
  level: _level4,
  activeDaysToNextLevel: 12,
  nextLevelIcon: LevelIcon.star,
);

void main() {
  test('starts with no progress', () {
    expect(LevelProgressBloc().state.progress, isNull);
  });

  blocTest<LevelProgressBloc, LevelProgressState>(
    'holds the latest progress it is told',
    build: LevelProgressBloc.new,
    act: (bloc) => bloc
      ..add(const LevelProgressUpdated(_at32))
      ..add(const LevelProgressUpdated(_at33)),
    expect: () => const [
      LevelProgressState(_at32),
      LevelProgressState(_at33),
    ],
  );

  blocTest<LevelProgressBloc, LevelProgressState>(
    'clearing it leaves no progress',
    build: LevelProgressBloc.new,
    seed: () => const LevelProgressState(_at32),
    act: (bloc) => bloc.add(const LevelProgressCleared()),
    expect: () => const [LevelProgressState(null)],
  );
}
