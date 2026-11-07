import 'package:dio/dio.dart';
import 'package:doormer/src/features/questions/data/datasource/question_sharing_remote_datasource.dart';
import 'package:doormer/src/features/questions/data/datasource/questions_local_datasource.dart';
import 'package:doormer/src/features/questions/data/datasource/questions_remote_datasource.dart';
import 'package:doormer/src/features/questions/data/repository/question_sharing_repository_impl.dart';
import 'package:doormer/src/features/questions/data/repository/questions_repository_impl.dart';
import 'package:doormer/src/features/questions/domain/repository/question_sharing_repository.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/block_friend_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_daily_limit_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_friends_to_share_with_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_quark_balance_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_question_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_sample_solution_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_shared_questions_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_solved_questions_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/remove_shared_question_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/report_shared_question_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/reveal_answer_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/share_question_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/stop_sharing_question_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/submit_photo_question_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/daily_limit_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/friend_question_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/saved_questions_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/share_question_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/shared_questions_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/solution_reader_bloc.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_file_input.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_platform.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_preparer.dart';
import 'package:get_it/get_it.dart';

final serviceLocator = GetIt.instance;

void initQuestionsModule() {
  serviceLocator.registerLazySingleton<QuestionsRemoteDataSource>(
    () => QuestionsRemoteDataSourceImpl(dio: serviceLocator<Dio>()),
  );

  serviceLocator.registerLazySingleton<QuestionsLocalDataSource>(
    () => QuestionsLocalDataSourceImpl(),
  );

  serviceLocator.registerLazySingleton<QuestionsRepository>(
    () => QuestionsRepositoryImpl(
      remoteDataSource: serviceLocator<QuestionsRemoteDataSource>(),
      localDataSource: serviceLocator<QuestionsLocalDataSource>(),
    ),
  );

  serviceLocator.registerLazySingleton<SubmitPhotoQuestionUseCase>(
    () => SubmitPhotoQuestionUseCase(serviceLocator<QuestionsRepository>()),
  );

  serviceLocator.registerLazySingleton<LoadDailyLimitUseCase>(
    () => LoadDailyLimitUseCase(serviceLocator<QuestionsRepository>()),
  );

  serviceLocator.registerLazySingleton<LoadSampleSolutionUseCase>(
    () => LoadSampleSolutionUseCase(serviceLocator<QuestionsRepository>()),
  );

  serviceLocator.registerLazySingleton<LoadQuestionUseCase>(
    () => LoadQuestionUseCase(serviceLocator<QuestionsRepository>()),
  );

  serviceLocator.registerLazySingleton<LoadSolvedQuestionsUseCase>(
    () => LoadSolvedQuestionsUseCase(serviceLocator<QuestionsRepository>()),
  );

  serviceLocator.registerFactory<SavedQuestionsBloc>(
    () => SavedQuestionsBloc(
      loadSolvedQuestions: serviceLocator<LoadSolvedQuestionsUseCase>(),
    ),
  );

  serviceLocator.registerFactory<AskByPhotoBloc>(
    () => AskByPhotoBloc(
      submitPhotoQuestionUseCase: serviceLocator<SubmitPhotoQuestionUseCase>(),
    ),
  );

  serviceLocator.registerFactory<DailyLimitBloc>(
    () => DailyLimitBloc(
      loadDailyLimitUseCase: serviceLocator<LoadDailyLimitUseCase>(),
    ),
  );

  serviceLocator.registerLazySingleton<LoadQuarkBalanceUseCase>(
    () => LoadQuarkBalanceUseCase(serviceLocator<QuestionsRepository>()),
  );

  serviceLocator.registerLazySingleton<RevealAnswerUseCase>(
    () => RevealAnswerUseCase(serviceLocator<QuestionsRepository>()),
  );

  serviceLocator.registerFactory<SolutionReaderBloc>(
    () => SolutionReaderBloc(
      loadSampleSolutionUseCase: serviceLocator<LoadSampleSolutionUseCase>(),
      loadQuestionUseCase: serviceLocator<LoadQuestionUseCase>(),
      loadQuarkBalanceUseCase: serviceLocator<LoadQuarkBalanceUseCase>(),
      revealAnswerUseCase: serviceLocator<RevealAnswerUseCase>(),
    ),
  );

  _initQuestionSharing();

  serviceLocator.registerLazySingleton<PhotoFileInput>(createPhotoFileInput);

  serviceLocator.registerLazySingleton<PhotoPreparer>(createPhotoPreparer);
}

/// Sharing solved questions with friends: Share on the reader, Shared with me
/// on Saved, and Remove, Report and Block on a question a friend shared.
void _initQuestionSharing() {
  serviceLocator.registerLazySingleton<QuestionSharingRemoteDataSource>(
    () => QuestionSharingRemoteDataSourceImpl(dio: serviceLocator<Dio>()),
  );

  serviceLocator.registerLazySingleton<QuestionSharingRepository>(
    () => QuestionSharingRepositoryImpl(
      remoteDataSource: serviceLocator<QuestionSharingRemoteDataSource>(),
    ),
  );

  serviceLocator.registerLazySingleton<LoadFriendsToShareWithUseCase>(
    () => LoadFriendsToShareWithUseCase(
        serviceLocator<QuestionSharingRepository>()),
  );

  serviceLocator.registerLazySingleton<ShareQuestionUseCase>(
    () => ShareQuestionUseCase(serviceLocator<QuestionSharingRepository>()),
  );

  serviceLocator.registerLazySingleton<StopSharingQuestionUseCase>(
    () =>
        StopSharingQuestionUseCase(serviceLocator<QuestionSharingRepository>()),
  );

  serviceLocator.registerLazySingleton<LoadSharedQuestionsUseCase>(
    () =>
        LoadSharedQuestionsUseCase(serviceLocator<QuestionSharingRepository>()),
  );

  serviceLocator.registerLazySingleton<RemoveSharedQuestionUseCase>(
    () => RemoveSharedQuestionUseCase(
        serviceLocator<QuestionSharingRepository>()),
  );

  serviceLocator.registerLazySingleton<ReportSharedQuestionUseCase>(
    () => ReportSharedQuestionUseCase(
        serviceLocator<QuestionSharingRepository>()),
  );

  serviceLocator.registerLazySingleton<BlockFriendUseCase>(
    () => BlockFriendUseCase(serviceLocator<QuestionSharingRepository>()),
  );

  serviceLocator.registerFactory<ShareQuestionBloc>(
    () => ShareQuestionBloc(
      loadFriends: serviceLocator<LoadFriendsToShareWithUseCase>(),
      shareQuestion: serviceLocator<ShareQuestionUseCase>(),
      stopSharing: serviceLocator<StopSharingQuestionUseCase>(),
    ),
  );

  serviceLocator.registerFactory<FriendQuestionBloc>(
    () => FriendQuestionBloc(
      removeSharedQuestion: serviceLocator<RemoveSharedQuestionUseCase>(),
      reportSharedQuestion: serviceLocator<ReportSharedQuestionUseCase>(),
      blockFriend: serviceLocator<BlockFriendUseCase>(),
    ),
  );

  serviceLocator.registerFactory<SharedQuestionsBloc>(
    () => SharedQuestionsBloc(
      loadSharedQuestions: serviceLocator<LoadSharedQuestionsUseCase>(),
    ),
  );
}
