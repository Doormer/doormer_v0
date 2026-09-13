// lib/src/features/collection/di/collection_module.dart
import 'package:get_it/get_it.dart';

import '../data/datasource/collection_local_datasource.dart';
import '../data/repository/collection_repository_impl.dart';
import '../domain/repository/collection_repository.dart';
import '../domain/usecase/convert_copy_usecase.dart';
import '../domain/usecase/draw_card_usecase.dart';
import '../domain/usecase/load_collection_usecase.dart';
import '../presentation/bloc/collection_bloc.dart';

final serviceLocator = GetIt.instance;

void initCollectionModule() {
  serviceLocator.registerLazySingleton<CollectionLocalDataSource>(
    () => CollectionLocalDataSourceImpl(),
  );

  // A singleton on purpose: the repository *is* the session's state, so a
  // second instance would silently discard every draw.
  serviceLocator.registerLazySingleton<CollectionRepository>(
    () => CollectionRepositoryImpl(
      dataSource: serviceLocator<CollectionLocalDataSource>(),
    ),
  );

  serviceLocator.registerLazySingleton(
    () => LoadCollectionUseCase(serviceLocator<CollectionRepository>()),
  );
  serviceLocator.registerLazySingleton(
    () => DrawCardUseCase(serviceLocator<CollectionRepository>()),
  );
  serviceLocator.registerLazySingleton(
    () => ConvertCopyUseCase(serviceLocator<CollectionRepository>()),
  );

  serviceLocator.registerFactory(
    () => CollectionBloc(
      loadCollection: serviceLocator<LoadCollectionUseCase>(),
      drawCard: serviceLocator<DrawCardUseCase>(),
      convertCopy: serviceLocator<ConvertCopyUseCase>(),
    ),
  );
}
