import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/features/levels/domain/usecase/count_active_day_usecase.dart';
import 'package:doormer/src/features/levels/presentation/bloc/active_day_bloc.dart';
import 'package:doormer/src/shared/levels/bloc/level_progress_bloc.dart';

import 'fake_levels_repository.dart';

/// Registers the app-wide level blocs as `initDependencies` does, for a test
/// that builds the nav bar shell or Profile. Each is made when first asked
/// for, inside the test's fake time, so its events are handled there.
///
/// [levels] answers the shell's counts. By default no count ever answers,
/// for tests that aren't about levels. Returns the repository, so a test can
/// see how often the day was counted.
FakeLevelsRepository registerLevels([FakeLevelsRepository? levels]) {
  final repository = levels ?? FakeLevelsRepository();
  serviceLocator.registerLazySingleton(LevelProgressBloc.new);
  serviceLocator.registerLazySingleton(
    () => ActiveDayBloc(
      countActiveDay: CountActiveDayUseCase(repository),
      levelProgress: serviceLocator<LevelProgressBloc>(),
    ),
  );
  return repository;
}
