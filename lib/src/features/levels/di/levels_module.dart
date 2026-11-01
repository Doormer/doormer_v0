import 'package:dio/dio.dart';
import 'package:doormer/src/shared/levels/bloc/level_progress_bloc.dart';
import 'package:get_it/get_it.dart';

import '../data/datasource/levels_remote_datasource.dart';
import '../data/repository/levels_repository_impl.dart';
import '../domain/repository/levels_repository.dart';
import '../domain/usecase/count_active_day_usecase.dart';
import '../presentation/bloc/active_day_bloc.dart';

final serviceLocator = GetIt.instance;

/// Needs the app's shared [Dio], so the bearer token and the app-wide 401
/// handling come for free, and the app-wide [LevelProgressBloc]. Call it
/// after both are registered.
void initLevelsModule() {
  serviceLocator.registerLazySingleton<LevelsRemoteDataSource>(
    () => LevelsRemoteDataSourceImpl(dio: serviceLocator<Dio>()),
  );
  serviceLocator.registerLazySingleton<LevelsRepository>(
    () => LevelsRepositoryImpl(
      remoteDataSource: serviceLocator<LevelsRemoteDataSource>(),
    ),
  );
  serviceLocator.registerLazySingleton(
    () => CountActiveDayUseCase(serviceLocator<LevelsRepository>()),
  );

  // One for the whole app: the nav bar shell asks it to count the day, and
  // it tells LevelProgressBloc what each count brings back.
  serviceLocator.registerSingleton<ActiveDayBloc>(
    ActiveDayBloc(
      countActiveDay: serviceLocator<CountActiveDayUseCase>(),
      levelProgress: serviceLocator<LevelProgressBloc>(),
    ),
  );
}
