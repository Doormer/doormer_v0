import 'dart:async';

import 'package:doormer/main.dart';
import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/collection/domain/repository/collection_repository.dart';
import 'package:doormer/src/features/levels/presentation/bloc/active_day_bloc.dart';
import 'package:doormer/src/shared/friends/bloc/waiting_friend_requests_bloc.dart';
import 'package:doormer/src/shared/levels/bloc/level_progress_bloc.dart';
import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:doormer/src/shared/levels/entity/level_progress.dart';
import 'package:doormer/src/shared/sessions/bloc/global_session_bloc.dart';
import 'package:doormer/src/shared/user/entity/user.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features/levels/fake_levels_repository.dart';
import 'features/levels/register_levels.dart';

/// Never asked anything: starting a session doesn't call it.
class _UnusedSessionService implements SessionService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Remembers no deck list, so forgetting it does nothing.
class _NothingRememberedCollectionRepository implements CollectionRepository {
  @override
  void forgetLastDeckList() {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

const _at32 = LevelProgress(
  activeDays: 32,
  level: Level(number: 4, suns: 0, moons: 1, stars: 0),
  activeDaysToNextLevel: 13,
  nextLevelIcon: LevelIcon.star,
);

void main() {
  setUpAll(AppLogger.disable);

  late FakeLevelsRepository levelsRepository;

  setUp(() {
    // Made when first asked for, inside the test's fake time, so their events
    // are handled there.
    serviceLocator.registerLazySingleton(
      () => GlobalSessionBloc(sessionService: _UnusedSessionService()),
    );
    serviceLocator.registerLazySingleton<CollectionRepository>(
      _NothingRememberedCollectionRepository.new,
    );
    serviceLocator.registerLazySingleton(WaitingFriendRequestsBloc.new);
    levelsRepository = registerLevels(FakeLevelsRepository([newMoonAt32]));
  });

  tearDown(() => serviceLocator.reset());

  // Whoever signs in may not be the student whose requests the dot counted.
  // Their own are counted once Profile loads.
  testWidgets("a session starting takes away the last student's dot",
      (tester) async {
    final waiting = serviceLocator<WaitingFriendRequestsBloc>()
      ..add(const WaitingFriendRequestsCounted(3));
    await tester.pumpWidget(const MyApp());
    expect(waiting.state.count, 3);

    serviceLocator<GlobalSessionBloc>()
        .add(SessionStarted(User(userRegistrationStatus: 1)));
    await tester.pump();

    expect(waiting.state.count, 0);
  });

  // Whoever signs in may not be the student whose level Profile showed.
  // Theirs comes with any count after signing in.
  testWidgets("a session starting takes away the last student's level",
      (tester) async {
    final levels = serviceLocator<LevelProgressBloc>()
      ..add(const LevelProgressUpdated(_at32));
    await tester.pumpWidget(const MyApp());
    expect(levels.state.progress, _at32);

    serviceLocator<GlobalSessionBloc>()
        .add(SessionStarted(User(userRegistrationStatus: 1)));
    await tester.pump();

    expect(levels.state.progress, isNull);
  });

  // A count still on its way when someone signs in was asked for the last
  // student. Its answer must not bring back their level, or their pop-up.
  testWidgets("a session starting drops the last student's count on its way",
      (tester) async {
    final lastStudentsAnswer = Completer<void>();
    levelsRepository.hold = lastStudentsAnswer;
    final activeDay = serviceLocator<ActiveDayBloc>()
      ..add(const ActiveDayCountRequested());
    await tester.pumpWidget(const MyApp());

    serviceLocator<GlobalSessionBloc>()
        .add(SessionStarted(User(userRegistrationStatus: 1)));
    await tester.pump();
    lastStudentsAnswer.complete();
    await tester.pump();

    expect(serviceLocator<LevelProgressBloc>().state.progress, isNull);
    expect(activeDay.state, const ActiveDayNotCounted());
  });
}
