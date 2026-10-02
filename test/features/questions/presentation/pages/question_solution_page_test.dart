import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/data/model/photo_question_response_model.dart';
import 'package:doormer/src/features/questions/domain/entity/answer_reward.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/quest_profile.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_quark_balance_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_quest_profile_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_sample_solution_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/reveal_answer_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/solution_reader_bloc.dart';
import 'package:doormer/src/features/questions/presentation/pages/question_solution_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves the real bundled payload, so this exercises the content students
/// actually get rather than a hand-written stand-in.
class _AssetRepository implements QuestionsRepository {
  @override
  Future<PhotoQuestionSolveOutcome> loadSampleSolution() async {
    final raw =
        File('assets/mock/mock_question_response.json').readAsStringSync();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return PhotoQuestionResponseModel.fromJson(json).toEntity();
  }

  @override
  Future<PhotoQuestionSolveOutcome> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<QuestProfile> loadQuestProfile() async => const QuestProfile(
        streakDays: 3,
        topic: 'Geometry - Area',
        questionTitle: 'Road through a field',
      );

  @override
  Future<int> loadQuarkBalance() async => 128;

  @override
  Future<AnswerReward> revealAnswer(String questionId) async =>
      const AnswerReward(quarksEarned: 3, quarkBalance: 131);
}

Widget _app({AskByPhotoSolved? solvedState}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: QuestionSolutionPage(questionId: '57', solvedState: solvedState),
    ),
  );
}

class _RecordingRepository extends _AssetRepository {
  final List<String> revealedIds = [];

  @override
  Future<AnswerReward> revealAnswer(String questionId) async {
    revealedIds.add(questionId);
    return const AnswerReward(quarksEarned: 3, quarkBalance: 131);
  }
}

/// The answer only unlocks on the last step, so tap the CTA off the briefing
/// and through every step, then once more to reveal. The reveal waits out the
/// vault's 450ms resistance before it fires.
Future<void> _revealTheAnswer(WidgetTester tester, int stepCount) async {
  for (var tap = 0; tap < stepCount; tap++) {
    await tester.tap(find.byKey(const Key('solution_cta')));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(const Key('solution_cta')));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  setUpAll(AppLogger.disable);

  setUp(() {
    final repository = _AssetRepository();
    serviceLocator.registerFactory<SolutionReaderBloc>(
      () => SolutionReaderBloc(
        loadSampleSolutionUseCase: LoadSampleSolutionUseCase(repository),
        loadQuestProfileUseCase: LoadQuestProfileUseCase(repository),
        loadQuarkBalanceUseCase: LoadQuarkBalanceUseCase(repository),
        revealAnswerUseCase: RevealAnswerUseCase(repository),
      ),
    );
  });

  tearDown(() async {
    await serviceLocator.reset();
  });

  testWidgets('opens on the briefing and renders the real approach text',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('solution_briefing')), findsOneWidget);
    expect(find.text('The plan'), findsOneWidget);
    expect(find.text('Start solving'), findsOneWidget);

    // The payload's approach opens with this phrase; asserting on real content
    // proves the text survived the whole chain, not just that a box exists.
    expect(find.textContaining('Frozen question-data ledger'), findsOneWidget);
  });

  testWidgets('shows the solver note on the briefing', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('solution_note')), findsOneWidget);
    expect(
      find.textContaining('not given directly'),
      findsOneWidget,
      reason: 'the note was dropped at two boundaries before this',
    );
  });

  testWidgets('walks briefing to step one and back again', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('solution_cta')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('solution_briefing')), findsNothing);
    expect(find.textContaining('LEVEL 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('solution_back')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('solution_briefing')), findsOneWidget);
  });

  testWidgets('carries a handed-over note from a solve', (tester) async {
    final outcome = await _AssetRepository().loadSampleSolution();

    await tester.pumpWidget(_app(
      solvedState: AskByPhotoSolved(
        questionId: '57',
        solution: outcome.solution!,
        note: 'Handed over from the solve.',
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Handed over from the solve.'), findsOneWidget);
  });

  testWidgets('carries handed-over topic and method from a solve',
      (tester) async {
    final outcome = await _AssetRepository().loadSampleSolution();

    await tester.pumpWidget(_app(
      solvedState: AskByPhotoSolved(
        questionId: '57',
        solution: outcome.solution!,
        topic: 'Algebra - Linear equations',
        method: 'Inverse operations',
      ),
    ));
    await tester.pumpAndSettle();

    final blocContext = tester.element(
      find.byType(BlocBuilder<SolutionReaderBloc, SolutionReaderState>),
    );

    expect(
      blocContext.read<SolutionReaderBloc>().state,
      isA<SolutionReaderReady>()
          .having((s) => s.topic, 'topic', 'Algebra - Linear equations')
          .having((s) => s.method, 'method', 'Inverse operations'),
    );
  });

  testWidgets('lands at the top of step one after a scrolled briefing',
      (tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // The real approach runs to 1330px on a 690px viewport, so a student
    // reaches "Start solving" only after scrolling well down the briefing.
    await tester.drag(
        find.byKey(const Key('solution_scroll')), const Offset(0, -600));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('solution_cta')));
    await tester.pumpAndSettle();

    final position = tester
        .state<ScrollableState>(find
            .descendant(
              of: find.byKey(const Key('solution_scroll')),
              matching: find.byType(Scrollable),
            )
            .first)
        .position;

    expect(position.pixels, 0);
    expect(tester.getTopLeft(find.textContaining('LEVEL 1')).dy,
        greaterThanOrEqualTo(0),
        reason: 'the step heading must not start scrolled off the top');
  });

  testWidgets('passes questionId only when the page has a solved handoff',
      (tester) async {
    final outcome = await _AssetRepository().loadSampleSolution();
    final stepCount = outcome.solution!.steps.length;

    await serviceLocator.reset();
    final solvedRepository = _RecordingRepository();
    serviceLocator.registerFactory<SolutionReaderBloc>(
      () => SolutionReaderBloc(
        loadSampleSolutionUseCase: LoadSampleSolutionUseCase(solvedRepository),
        loadQuestProfileUseCase: LoadQuestProfileUseCase(solvedRepository),
        loadQuarkBalanceUseCase: LoadQuarkBalanceUseCase(solvedRepository),
        revealAnswerUseCase: RevealAnswerUseCase(solvedRepository),
      ),
    );

    await tester.pumpWidget(_app(
      solvedState: AskByPhotoSolved(
        questionId: '57',
        solution: outcome.solution!,
        note: 'Handed over from the solve.',
      ),
    ));
    await tester.pumpAndSettle();
    await _revealTheAnswer(tester, stepCount);

    expect(solvedRepository.revealedIds, ['57']);

    // Unmount the solved page so the sample run builds a fresh BLoC instead
    // of reusing this one.
    await tester.pumpWidget(const SizedBox());
    await serviceLocator.reset();
    final sampleRepository = _RecordingRepository();
    serviceLocator.registerFactory<SolutionReaderBloc>(
      () => SolutionReaderBloc(
        loadSampleSolutionUseCase: LoadSampleSolutionUseCase(sampleRepository),
        loadQuestProfileUseCase: LoadQuestProfileUseCase(sampleRepository),
        loadQuarkBalanceUseCase: LoadQuarkBalanceUseCase(sampleRepository),
        revealAnswerUseCase: RevealAnswerUseCase(sampleRepository),
      ),
    );

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _revealTheAnswer(tester, stepCount);

    expect(sampleRepository.revealedIds, isEmpty);
  });
}
