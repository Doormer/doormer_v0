import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/levels/domain/usecase/count_active_day_usecase.dart';
import 'package:doormer/src/features/levels/presentation/bloc/active_day_bloc.dart';
import 'package:doormer/src/shared/levels/bloc/level_progress_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_levels_repository.dart';

ActiveDayBloc _bloc(
  FakeLevelsRepository levels, {
  LevelProgressBloc? levelProgress,
}) =>
    ActiveDayBloc(
      countActiveDay: CountActiveDayUseCase(levels),
      levelProgress: levelProgress ?? LevelProgressBloc(),
    );

void main() {
  setUpAll(AppLogger.disable);

  test('starts with nothing counted', () {
    expect(_bloc(FakeLevelsRepository()).state, const ActiveDayNotCounted());
  });

  blocTest<ActiveDayBloc, ActiveDayState>(
    'counts the day, and says when it raised the level',
    build: () => _bloc(FakeLevelsRepository([newMoonAt32])),
    act: (bloc) => bloc.add(const ActiveDayCountRequested()),
    expect: () => const [ActiveDayCounting(), ActiveDayCounted(newMoonAt32)],
    verify: (bloc) =>
        expect((bloc.state as ActiveDayCounted).outcome.raisedLevel, isTrue),
  );

  blocTest<ActiveDayBloc, ActiveDayState>(
    'a day already counted raises nothing',
    build: () => _bloc(FakeLevelsRepository([alreadyCountedAt32])),
    act: (bloc) => bloc.add(const ActiveDayCountRequested()),
    expect: () => const [
      ActiveDayCounting(),
      ActiveDayCounted(alreadyCountedAt32),
    ],
    verify: (bloc) =>
        expect((bloc.state as ActiveDayCounted).outcome.raisedLevel, isFalse),
  );

  test('tells the app-wide progress what each count brings back', () async {
    final levelProgress = LevelProgressBloc();
    final bloc = _bloc(
      FakeLevelsRepository([newMoonAt32]),
      levelProgress: levelProgress,
    );

    bloc.add(const ActiveDayCountRequested());

    await expectLater(
      levelProgress.stream,
      emits(LevelProgressState(newMoonAt32.progress)),
    );
  });

  test(
      'a count that fails ends in an error nothing shows, and the progress '
      'stays as it was', () async {
    final levelProgress = LevelProgressBloc()
      ..add(LevelProgressUpdated(alreadyCountedAt32.progress));
    final levels = FakeLevelsRepository()
      ..failNext = ServerFailure("We couldn't count today as an active day.");
    final bloc = _bloc(levels, levelProgress: levelProgress);

    bloc.add(const ActiveDayCountRequested());

    await expectLater(
      bloc.stream,
      emitsInOrder(const [
        ActiveDayCounting(),
        ActiveDayError("We couldn't count today as an active day."),
      ]),
    );
    expect(levelProgress.state.progress, alreadyCountedAt32.progress);
  });

  blocTest<ActiveDayBloc, ActiveDayState>(
    'an error that is not a Failure ends the same way',
    build: () => _bloc(FakeLevelsRepository()..failNext = StateError('boom')),
    act: (bloc) => bloc.add(const ActiveDayCountRequested()),
    expect: () => const [
      ActiveDayCounting(),
      ActiveDayError('An unexpected error occurred'),
    ],
  );

  test('a request while a count is on its way asks the API only once',
      () async {
    final levels = FakeLevelsRepository([newMoonAt32])
      ..hold = Completer<void>();
    final bloc = _bloc(levels);

    bloc
      ..add(const ActiveDayCountRequested())
      ..add(const ActiveDayCountRequested());
    await Future<void>.delayed(Duration.zero);
    levels.hold!.complete();

    await expectLater(bloc.stream, emits(const ActiveDayCounted(newMoonAt32)));
    expect(levels.counts, 1);
  });
}
