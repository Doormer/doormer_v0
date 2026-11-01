import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/levels/domain/entity/active_day_outcome.dart';
import 'package:doormer/src/features/levels/domain/usecase/count_active_day_usecase.dart';
import 'package:doormer/src/features/levels/presentation/bloc/active_day_bloc.dart';
import 'package:doormer/src/shared/levels/bloc/level_progress_bloc.dart';
import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:doormer/src/shared/levels/entity/level_progress.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_levels_repository.dart';

/// Another student's first active day: level 0, 4 days from a star.
const _countedAt1 = ActiveDayOutcome(
  counted: true,
  progress: LevelProgress(
    activeDays: 1,
    level: Level(number: 0, suns: 0, moons: 0, stars: 0),
    activeDaysToNextLevel: 4,
    nextLevelIcon: LevelIcon.star,
  ),
);

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

  // Whoever signs in may be another student, so the answer to a count asked
  // for before the session started is the last student's.
  group('a new session', () {
    late FakeLevelsRepository levels;
    late LevelProgressBloc levelProgress;

    blocTest<ActiveDayBloc, ActiveDayState>(
      "drops the answer to the last student's count, and counts the new "
      "student's day",
      setUp: () {
        // The last student's count waits for its answer while the new
        // student's goes ahead, so the new student's outcome comes first.
        levels = FakeLevelsRepository([_countedAt1, newMoonAt32])
          ..hold = Completer<void>();
        levelProgress = LevelProgressBloc();
      },
      build: () => _bloc(levels, levelProgress: levelProgress),
      act: (bloc) async {
        bloc.add(const ActiveDayCountRequested());
        await Future<void>.delayed(Duration.zero);
        final lastStudentsAnswer = levels.hold!;
        levels.hold = null;

        bloc
          ..add(const ActiveDaySessionStarted())
          ..add(const ActiveDayCountRequested());
        await Future<void>.delayed(Duration.zero);
        lastStudentsAnswer.complete();
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => const [
        ActiveDayCounting(),
        ActiveDayNotCounted(),
        ActiveDayCounting(),
        ActiveDayCounted(_countedAt1),
      ],
      verify: (_) => expect(levelProgress.state.progress, _countedAt1.progress),
    );

    blocTest<ActiveDayBloc, ActiveDayState>(
      'with no count on its way starts afresh, and the next count goes ahead',
      build: () => _bloc(FakeLevelsRepository([newMoonAt32, _countedAt1])),
      act: (bloc) async {
        bloc.add(const ActiveDayCountRequested());
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(const ActiveDaySessionStarted())
          ..add(const ActiveDayCountRequested());
      },
      expect: () => const [
        ActiveDayCounting(),
        ActiveDayCounted(newMoonAt32),
        ActiveDayNotCounted(),
        ActiveDayCounting(),
        ActiveDayCounted(_countedAt1),
      ],
    );

    for (final (name, error) in [
      ('a Failure', ServerFailure("We couldn't count today as an active day.")),
      ('any other error', StateError('boom')),
    ]) {
      blocTest<ActiveDayBloc, ActiveDayState>(
        "drops the last student's count that fails afterwards, with $name",
        setUp: () => levels = FakeLevelsRepository()
          ..failNext = error
          ..hold = Completer<void>(),
        build: () => _bloc(levels),
        act: (bloc) async {
          bloc.add(const ActiveDayCountRequested());
          await Future<void>.delayed(Duration.zero);
          bloc.add(const ActiveDaySessionStarted());
          await Future<void>.delayed(Duration.zero);
          levels.hold!.complete();
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => const [ActiveDayCounting(), ActiveDayNotCounted()],
      );
    }
  });
}
