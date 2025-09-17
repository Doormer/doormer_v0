import 'package:dio/dio.dart';
import 'package:doormer/src/features/mistake_mirror/data/datasource/mistake_mirror_local_datasource.dart';
import 'package:doormer/src/features/mistake_mirror/data/datasource/mistake_mirror_remote_datasource.dart';
import 'package:doormer/src/features/mistake_mirror/data/repository/mistake_mirror_repository_impl.dart';
import 'package:doormer/src/features/mistake_mirror/domain/repository/mistake_mirror_repository.dart';
import 'package:doormer/src/features/mistake_mirror/domain/usecase/mistake_mirror_usecase.dart';
import 'package:doormer/src/features/mistake_mirror/presentation/bloc/mistake_mirror_bloc.dart';
import 'package:get_it/get_it.dart';

final serviceLocator = GetIt.instance;

void initMistakeMirrorModule() {
  // Register MistakeMirrorRemoteDataSource
  serviceLocator.registerLazySingleton(() => MistakeMirrorRemoteDataSource(
        dio: serviceLocator<Dio>(),
      ));

  // Register MistakeMirrorLocalDataSource
  serviceLocator.registerLazySingleton<MistakeMirrorLocalDataSource>(
    () => MistakeMirrorLocalDataSource(),
  );

  // Register MistakeMirrorRepository
  serviceLocator.registerLazySingleton<MistakeMirrorRepository>(
    () => MistakeMirrorRepositoryImpl(
      remoteDataSource: serviceLocator<MistakeMirrorRemoteDataSource>(),
      localDataSource: serviceLocator<MistakeMirrorLocalDataSource>(),
    ),
  );

  // Register MistakeMirrorUseCase with the injected repository
  serviceLocator.registerLazySingleton<MistakeMirrorUseCase>(
    () => MistakeMirrorUseCase(serviceLocator<MistakeMirrorRepository>()),
  );

  // Register MistakeMirrorBloc with the injected MistakeMirrorUseCase
  serviceLocator.registerFactory<MistakeMirrorBloc>(
    () => MistakeMirrorBloc(
      mistakeMirrorUseCase: serviceLocator<MistakeMirrorUseCase>(),
    ),
  );
}
