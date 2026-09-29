// lib/src/features/collection/di/collection_module.dart
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../data/datasource/collection_remote_datasource.dart';
import '../data/repository/collection_repository_impl.dart';
import '../domain/repository/collection_repository.dart';
import '../domain/usecase/draw_card_usecase.dart';
import '../domain/usecase/load_collection_usecase.dart';
import '../domain/usecase/load_decks_usecase.dart';
import '../domain/usecase/shatter_copy_usecase.dart';
import '../presentation/bloc/collection_bloc.dart';

final serviceLocator = GetIt.instance;

/// Needs the app's shared [Dio], so the bearer token and the app-wide 401
/// handling come for free. Call it after Dio is registered.
void initCollectionModule() {
  serviceLocator.registerLazySingleton<CollectionRemoteDataSource>(
    () => CollectionRemoteDataSourceImpl(dio: serviceLocator<Dio>()),
  );

  // A singleton on purpose: the idempotency keys it keeps for lost answers
  // have to survive leaving and reopening the page.
  serviceLocator.registerLazySingleton<CollectionRepository>(
    () => CollectionRepositoryImpl(
      remoteDataSource: serviceLocator<CollectionRemoteDataSource>(),
    ),
  );

  serviceLocator.registerLazySingleton(
    () => LoadDecksUseCase(serviceLocator<CollectionRepository>()),
  );
  serviceLocator.registerLazySingleton(
    () => LoadCollectionUseCase(serviceLocator<CollectionRepository>()),
  );
  serviceLocator.registerLazySingleton(
    () => DrawCardUseCase(serviceLocator<CollectionRepository>()),
  );
  serviceLocator.registerLazySingleton(
    () => ShatterCopyUseCase(serviceLocator<CollectionRepository>()),
  );

  serviceLocator.registerFactory(
    () => CollectionBloc(
      loadDecks: serviceLocator<LoadDecksUseCase>(),
      loadCollection: serviceLocator<LoadCollectionUseCase>(),
      drawCard: serviceLocator<DrawCardUseCase>(),
      shatterCopy: serviceLocator<ShatterCopyUseCase>(),
    ),
  );
}
