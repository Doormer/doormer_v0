import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:get_it/get_it.dart';

import '../domain/usecase/sign_out_usecase.dart';
import '../presentation/bloc/profile_bloc.dart';

final serviceLocator = GetIt.instance;

void initProfileModule() {
  serviceLocator.registerLazySingleton(
    () => SignOutUseCase(serviceLocator<SessionService>()),
  );
  serviceLocator.registerFactory(
    () => ProfileBloc(signOut: serviceLocator<SignOutUseCase>()),
  );
}
