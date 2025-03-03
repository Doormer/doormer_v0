import 'package:dio/dio.dart';
import 'package:doormer/src/features/registration/data/datasource/registration_local_datasource.dart';
import 'package:doormer/src/features/registration/data/datasource/registration_remote_datasource,dart';
import 'package:doormer/src/features/registration/data/repository/registration_repository_impl.dart';
import 'package:doormer/src/features/registration/domain/repository/registration_repository.dart';
import 'package:doormer/src/features/registration/domain/usecase/registration_usecase.dart';
import 'package:doormer/src/features/registration/presentation/bloc/document_upload/registration_document_bloc.dart';
import 'package:doormer/src/features/registration/presentation/bloc/registration/registration_bloc.dart';
import 'package:get_it/get_it.dart';

final serviceLocator = GetIt.instance;

void initRegisterModule() {
  // Register RegistrationRemoteDatasource
  serviceLocator.registerLazySingleton(() => RegistrationRemoteDataSource(
        dio: serviceLocator<Dio>(),
      ));

  // Register local data source
  serviceLocator.registerLazySingleton<RegistrationLocalDataSource>(
    () => RegistrationLocalDataSource(),
  );

  // Register RegistrationRepository
  serviceLocator.registerLazySingleton<RegistrationRepository>(
      () => RegistrationRepositoryImpl(
            remoteDataSource: serviceLocator<RegistrationRemoteDataSource>(),
            localDataSource: serviceLocator<RegistrationLocalDataSource>(),
          ));

  // Register RegistrationUseCase with the injected repository
  serviceLocator.registerLazySingleton<RegistrationUseCase>(
    () => RegistrationUseCase(serviceLocator<RegistrationRepository>()),
  );

  // Register RegistrationBloc with the injected RegistrationUseCase
  serviceLocator.registerFactory<RegistrationBloc>(
    () => RegistrationBloc(
      registrationUseCase: serviceLocator<RegistrationUseCase>(),
    ),
  );

  serviceLocator.registerFactory<RegistrationDocumentBloc>(
    () => RegistrationDocumentBloc(),
  );
}
