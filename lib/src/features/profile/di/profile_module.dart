import 'package:dio/dio.dart';
import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:get_it/get_it.dart';

import '../data/datasource/friends_remote_datasource.dart';
import '../data/repository/friends_repository_impl.dart';
import '../domain/repository/friends_repository.dart';
import '../domain/usecase/accept_friend_request_usecase.dart';
import '../domain/usecase/block_student_usecase.dart';
import '../domain/usecase/decline_friend_request_usecase.dart';
import '../domain/usecase/find_student_usecase.dart';
import '../domain/usecase/load_blocked_students_usecase.dart';
import '../domain/usecase/load_friend_profile_usecase.dart';
import '../domain/usecase/load_friend_requests_usecase.dart';
import '../domain/usecase/load_friends_usecase.dart';
import '../domain/usecase/load_picture_choices_usecase.dart';
import '../domain/usecase/remove_friend_usecase.dart';
import '../domain/usecase/report_student_usecase.dart';
import '../domain/usecase/reset_friend_code_usecase.dart';
import '../domain/usecase/save_friend_profile_usecase.dart';
import '../domain/usecase/send_friend_request_usecase.dart';
import '../domain/usecase/sign_out_usecase.dart';
import '../domain/usecase/unblock_student_usecase.dart';
import '../presentation/bloc/profile_bloc.dart';

final serviceLocator = GetIt.instance;

/// Needs the app's shared [Dio], so the bearer token and the app-wide 401
/// handling come for free. Call it after Dio is registered.
void initProfileModule() {
  serviceLocator.registerLazySingleton(
    () => SignOutUseCase(serviceLocator<SessionService>()),
  );

  serviceLocator.registerLazySingleton<FriendsRemoteDataSource>(
    () => FriendsRemoteDataSourceImpl(dio: serviceLocator<Dio>()),
  );
  serviceLocator.registerLazySingleton<FriendsRepository>(
    () => FriendsRepositoryImpl(
      remoteDataSource: serviceLocator<FriendsRemoteDataSource>(),
    ),
  );

  serviceLocator.registerLazySingleton(
    () => LoadFriendProfileUseCase(serviceLocator<FriendsRepository>()),
  );
  serviceLocator.registerLazySingleton(
    () => SaveFriendProfileUseCase(serviceLocator<FriendsRepository>()),
  );
  serviceLocator.registerLazySingleton(
    () => LoadPictureChoicesUseCase(serviceLocator<FriendsRepository>()),
  );
  serviceLocator.registerLazySingleton(
    () => ResetFriendCodeUseCase(serviceLocator<FriendsRepository>()),
  );
  serviceLocator.registerLazySingleton(
    () => FindStudentUseCase(serviceLocator<FriendsRepository>()),
  );
  serviceLocator.registerLazySingleton(
    () => LoadFriendRequestsUseCase(serviceLocator<FriendsRepository>()),
  );
  serviceLocator.registerLazySingleton(
    () => SendFriendRequestUseCase(serviceLocator<FriendsRepository>()),
  );
  serviceLocator.registerLazySingleton(
    () => AcceptFriendRequestUseCase(serviceLocator<FriendsRepository>()),
  );
  serviceLocator.registerLazySingleton(
    () => DeclineFriendRequestUseCase(serviceLocator<FriendsRepository>()),
  );
  serviceLocator.registerLazySingleton(
    () => LoadFriendsUseCase(serviceLocator<FriendsRepository>()),
  );
  serviceLocator.registerLazySingleton(
    () => RemoveFriendUseCase(serviceLocator<FriendsRepository>()),
  );
  serviceLocator.registerLazySingleton(
    () => BlockStudentUseCase(serviceLocator<FriendsRepository>()),
  );
  serviceLocator.registerLazySingleton(
    () => UnblockStudentUseCase(serviceLocator<FriendsRepository>()),
  );
  serviceLocator.registerLazySingleton(
    () => LoadBlockedStudentsUseCase(serviceLocator<FriendsRepository>()),
  );
  serviceLocator.registerLazySingleton(
    () => ReportStudentUseCase(serviceLocator<FriendsRepository>()),
  );

  serviceLocator.registerFactory(
    () => ProfileBloc(signOut: serviceLocator<SignOutUseCase>()),
  );
}
