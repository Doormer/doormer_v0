import 'package:dio/dio.dart';
import 'package:doormer/src/features/questions/data/datasource/questions_local_datasource.dart';
import 'package:doormer/src/features/questions/data/datasource/questions_remote_datasource.dart';
import 'package:doormer/src/features/questions/data/repository/questions_repository_impl.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_quark_balance_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_question_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_sample_solution_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_solved_questions_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/reveal_answer_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/submit_photo_question_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/saved_questions_bloc.dart';
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

  serviceLocator.registerLazySingleton<PhotoFileInput>(createPhotoFileInput);

  serviceLocator.registerLazySingleton<PhotoPreparer>(createPhotoPreparer);
}
