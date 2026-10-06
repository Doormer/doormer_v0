import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/routes/question_solution_routes.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/data/model/photo_question_response_model.dart';
import 'package:doormer/src/features/questions/domain/entity/answer_reward.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_questions_page.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_question_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_quark_balance_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_sample_solution_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/reveal_answer_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/solution_reader_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _RecordingRepository implements QuestionsRepository {
  final List<String> loadedIds = [];
  int sampleCalls = 0;

  Future<PhotoQuestionSolveOutcome> _asset(
      {String questionId = 'sample'}) async {
    final raw =
        File('assets/mock/mock_question_response.json').readAsStringSync();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return PhotoQuestionResponseModel.fromJson({
      ...json,
      'question_id': questionId,
    }).toEntity();
  }

  @override
  Future<PhotoQuestionSolveOutcome> loadSampleSolution() async {
    sampleCalls++;
    return _asset();
  }

  @override
  Future<PhotoQuestionSolveOutcome> loadQuestion(String questionId) async {
    loadedIds.add(questionId);
    return _asset(questionId: questionId);
  }

  @override
  Future<int> loadQuarkBalance() async => 128;

  @override
  Future<SolvedQuestionsPage> loadSolvedQuestions({String? cursor}) =>
      throw UnimplementedError();

  @override
  Future<AnswerReward> revealAnswer(String questionId) async =>
      const AnswerReward(quarksEarned: 3, quarkBalance: 131);

  @override
  Future<PhotoQuestionSolveOutcome> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
  }) =>
      throw UnimplementedError();
}

void main() {
  setUpAll(AppLogger.disable);

  late _RecordingRepository repository;

  setUp(() {
    repository = _RecordingRepository();
    serviceLocator.registerFactory<SolutionReaderBloc>(
      () => SolutionReaderBloc(
        loadSampleSolutionUseCase: LoadSampleSolutionUseCase(repository),
        loadQuestionUseCase: LoadQuestionUseCase(repository),
        loadQuarkBalanceUseCase: LoadQuarkBalanceUseCase(repository),
        revealAnswerUseCase: RevealAnswerUseCase(repository),
      ),
    );
  });

  tearDown(() async => serviceLocator.reset());

  Future<void> pumpRoute(WidgetTester tester, String initialLocation) async {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: questionSolutionRoutes,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp.router(
          theme: AppTheme.dark,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sample route opens the sample with no question id',
      (tester) async {
    await pumpRoute(tester, '/questions/sample/solution');

    expect(repository.sampleCalls, 1);
    expect(repository.loadedIds, isEmpty);
    expect(find.text('The plan'), findsOneWidget);
  });

  testWidgets('question route opens the address question by id',
      (tester) async {
    await pumpRoute(tester, '/questions/57/solution');

    expect(repository.sampleCalls, 0);
    expect(repository.loadedIds, ['57']);
    expect(find.text('The plan'), findsOneWidget);
  });
}
