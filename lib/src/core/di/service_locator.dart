import 'package:dio/dio.dart';
import 'package:doormer/src/core/connection/dio_client.dart';
import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:doormer/src/core/services/sessions/session_service_impl.dart';
import 'package:doormer/src/core/utils/invite_code_storage/invite_code_storage.dart';
import 'package:doormer/src/core/utils/invite_code_storage/invite_code_storage_web.dart';
import 'package:doormer/src/core/utils/token_storage/token_storage.dart';
import 'package:doormer/src/core/utils/token_storage/token_storage_web.dart';
import 'package:doormer/src/features/auth/di/auth_module.dart';
import 'package:doormer/src/features/collection/di/collection_module.dart';
import 'package:doormer/src/features/levels/di/levels_module.dart';
import 'package:doormer/src/features/profile/di/profile_module.dart';
import 'package:doormer/src/features/questions/di/questions_module.dart';
import 'package:doormer/src/shared/friends/bloc/waiting_friend_requests_bloc.dart';
import 'package:doormer/src/shared/levels/bloc/level_progress_bloc.dart';
import 'package:doormer/src/shared/sessions/bloc/global_session_bloc.dart';

import 'package:get_it/get_it.dart';

final serviceLocator = GetIt.instance;

Future<void> initDependencies() async {
  // Register TokenStorage based on platform

  serviceLocator.registerSingleton<TokenStorage>(TokenStorageWeb());

  // The friend code of an invite link, kept until the student reaches the app.
  serviceLocator.registerSingleton<InviteCodeStorage>(InviteCodeStorageWeb());

  // Register Session Service (with token and dio)
  serviceLocator.registerLazySingleton<SessionService>(
    () => SessionServiceImpl(
      tokenStorage: serviceLocator<TokenStorage>(),
      dio: Dio(), // Temporary basic Dio instance
    ),
  );

  // Register GlobalSessionBloc
  serviceLocator.registerSingleton<GlobalSessionBloc>(
    GlobalSessionBloc(
      sessionService: serviceLocator<SessionService>(),
    ),
  );

  // The count behind the dot on the nav bar's Profile item. Profile's
  // friends bloc keeps it up to date.
  serviceLocator.registerSingleton<WaitingFriendRequestsBloc>(
    WaitingFriendRequestsBloc(),
  );

  // The signed-in student's latest level progress, for Profile's level
  // strip. The levels feature's active day bloc keeps it up to date.
  serviceLocator.registerSingleton<LevelProgressBloc>(LevelProgressBloc());

  // Register Dio
  serviceLocator.registerLazySingleton<Dio>(
    () => DioClient.createDio(
      sessionService: serviceLocator<SessionService>(),
      sessionBloc: serviceLocator<GlobalSessionBloc>(),
    ),
  );

  // Inject the fully configured Dio into SessionService
  final sessionService = serviceLocator<SessionService>() as SessionServiceImpl;
  sessionService.setDio(serviceLocator<Dio>());

  // Initialize feature-specific modules
  initAuthModule(); // Initializes dependencies for the auth feature
  initQuestionsModule();
  initCollectionModule();
  initProfileModule();
  // After Dio and LevelProgressBloc, which its active day bloc needs.
  initLevelsModule();
}
