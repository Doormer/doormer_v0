import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/data/model/photo_question_response_model.dart';
import 'package:doormer/src/features/questions/domain/entity/answer_reward.dart';
import 'package:doormer/src/features/questions/domain/entity/daily_limit.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_questions_page.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_question_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_quark_balance_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_sample_solution_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/reveal_answer_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/friend_question_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/share_question_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/solution_reader_bloc.dart';
import 'package:doormer/src/features/questions/presentation/pages/question_solution_page.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/molecules/confirm_dialog_molecule.dart';
import 'package:doormer/src/shared/design/atomic/organisms/report_sheet_organism.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../fake_question_sharing_repository.dart';

/// Serves the real bundled payload, so this exercises the content students
/// actually get rather than a hand-written stand-in.
class _AssetRepository implements QuestionsRepository {
  final List<String> loadedIds = [];
  Object? loadQuestionError;

  /// Who a question loaded by id is shared with, as the API sends it.
  List<Map<String, Object?>> sharedWith = const [];

  /// The friend who shared a question loaded by id, as the API sends them.
  /// Null for the student's own question.
  Map<String, Object?>? sharedBy;

  @override
  Future<PhotoQuestionSolveOutcome> loadSampleSolution() async {
    final raw =
        File('assets/mock/mock_question_response.json').readAsStringSync();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return PhotoQuestionResponseModel.fromJson(json).toEntity();
  }

  @override
  Future<PhotoQuestionSolveOutcome> loadQuestion(String questionId) async {
    final error = loadQuestionError;
    if (error != null) throw error;

    loadedIds.add(questionId);
    final raw =
        File('assets/mock/mock_question_response.json').readAsStringSync();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return PhotoQuestionResponseModel.fromJson({
      ...json,
      'question_id': questionId,
      'shared_with': sharedWith,
      if (sharedBy != null) 'shared_by': sharedBy,
    }).toEntity();
  }

  @override
  Future<PhotoQuestionSolveOutcome> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
    required String idempotencyKey,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<DailyLimit> loadDailyLimit() => throw UnimplementedError();

  @override
  Future<int> loadQuarkBalance() async => 128;

  @override
  Future<SolvedQuestionsPage> loadSolvedQuestions({String? cursor}) =>
      throw UnimplementedError();

  @override
  Future<AnswerReward> revealAnswer(String questionId) async =>
      const AnswerReward(quarksEarned: 3, quarkBalance: 131);
}

Widget _app({String? questionId = '57', AskByPhotoSolved? solvedState}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: QuestionSolutionPage(
        questionId: questionId,
        solvedState: solvedState,
      ),
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

/// Registers the reader's bloc, playing [repository], and the bloc that
/// shares the student's own question, playing [sharing].
void _registerReader(
  QuestionsRepository repository, {
  FakeQuestionSharingRepository? sharing,
}) {
  serviceLocator.registerFactory<SolutionReaderBloc>(
    () => SolutionReaderBloc(
      loadSampleSolutionUseCase: LoadSampleSolutionUseCase(repository),
      loadQuestionUseCase: LoadQuestionUseCase(repository),
      loadQuarkBalanceUseCase: LoadQuarkBalanceUseCase(repository),
      revealAnswerUseCase: RevealAnswerUseCase(repository),
    ),
  );
  registerQuestionSharingBlocs(sharing ?? FakeQuestionSharingRepository());
}

void main() {
  setUpAll(AppLogger.disable);

  setUp(() {
    final repository = _AssetRepository();
    _registerReader(repository);
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

  testWidgets('with an id and no handover, loads that question by id',
      (tester) async {
    await serviceLocator.reset();
    final repository = _AssetRepository();
    _registerReader(repository);

    await tester.pumpWidget(_app(questionId: '57'));
    await tester.pumpAndSettle();

    expect(repository.loadedIds, ['57']);
    expect(find.byKey(const Key('solution_briefing')), findsOneWidget);
    expect(find.text('The plan'), findsOneWidget);
  });

  /// Pumps [routes] at [location], with every question failing to load, as one
  /// that no longer exists does.
  Future<GoRouter> pumpUnloadableQuestion(
    WidgetTester tester, {
    required String location,
    required List<RouteBase> routes,
  }) async {
    await serviceLocator.reset();
    final repository = _AssetRepository()
      ..loadQuestionError = ApiFailure(404, 'That question does not exist.');
    _registerReader(repository);
    final router = GoRouter(initialLocation: location, routes: routes);
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
    return router;
  }

  testWidgets('error state shows Back to Solve and returns to Solve',
      (tester) async {
    await pumpUnloadableQuestion(
      tester,
      location: '/questions/999999/solution',
      routes: [
        GoRoute(
          path: '/questions/photo',
          builder: (_, __) => const Scaffold(body: Text('Solve page')),
        ),
        GoRoute(
          path: '/questions/:questionId/solution',
          builder: (_, state) => QuestionSolutionPage(
            questionId: state.pathParameters['questionId'],
          ),
        ),
      ],
    );

    expect(find.text("We couldn't find this question."), findsOneWidget);
    expect(find.text('Back to Solve'), findsOneWidget);

    await tester.tap(find.byKey(const Key('solution_back')));
    await tester.pumpAndSettle();

    expect(find.text('Solve page'), findsOneWidget);
  });

  testWidgets('opened from Saved, the error state goes Back to Saved',
      (tester) async {
    final router = await pumpUnloadableQuestion(
      tester,
      location: '/saved/999999/solution',
      routes: [
        GoRoute(
          path: '/saved',
          builder: (_, __) => const Scaffold(body: Text('Saved page')),
          routes: [
            GoRoute(
              path: ':questionId/solution',
              builder: (_, state) => QuestionSolutionPage(
                questionId: state.pathParameters['questionId'],
                tabLocation: '/saved',
                tabName: 'Saved',
              ),
            ),
          ],
        ),
      ],
    );

    expect(find.text("We couldn't find this question."), findsOneWidget);
    expect(find.text('Back to Saved'), findsOneWidget);

    await tester.tap(find.byKey(const Key('solution_back')));
    await tester.pumpAndSettle();

    expect(find.text('Saved page'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/saved');
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

  testWidgets(
      'shows the sample question\'s own topic and method, and no streak',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('GEOMETRY - AREA'), findsOneWidget);
    expect(find.text('Trigonometry and parallelogram area'), findsOneWidget);
    expect(find.byKey(const Key('hud_streak')), findsNothing);
  });

  testWidgets('shows the topic and method handed over from a solve',
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

    expect(find.text('ALGEBRA - LINEAR EQUATIONS'), findsOneWidget);
    expect(find.text('Inverse operations'), findsOneWidget);
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

  testWidgets('passes questionId to reveal for handoff and id-loaded pages',
      (tester) async {
    final outcome = await _AssetRepository().loadSampleSolution();
    final stepCount = outcome.solution!.steps.length;

    await serviceLocator.reset();
    final solvedRepository = _RecordingRepository();
    _registerReader(solvedRepository);

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

    await tester.pumpWidget(const SizedBox());
    await serviceLocator.reset();
    final loadedRepository = _RecordingRepository();
    _registerReader(loadedRepository);

    await tester.pumpWidget(_app(questionId: '57'));
    await tester.pumpAndSettle();
    await _revealTheAnswer(tester, stepCount);

    expect(loadedRepository.loadedIds, ['57']);
    expect(loadedRepository.revealedIds, ['57']);
  });

  testWidgets('the sample page never pays', (tester) async {
    final outcome = await _AssetRepository().loadSampleSolution();
    final stepCount = outcome.solution!.steps.length;

    await serviceLocator.reset();
    final sampleRepository = _RecordingRepository();
    _registerReader(sampleRepository);

    await tester.pumpWidget(_app(questionId: null));
    await tester.pumpAndSettle();
    await _revealTheAnswer(tester, stepCount);

    expect(sampleRepository.loadedIds, isEmpty);
    expect(sampleRepository.revealedIds, isEmpty);
  });

  group('sharing your own question', () {
    late _AssetRepository repository;
    late FakeQuestionSharingRepository sharing;

    setUp(() async {
      await serviceLocator.reset();
      repository = _AssetRepository();
      sharing = FakeQuestionSharingRepository();
      _registerReader(repository, sharing: sharing);
    });

    /// Opens the reader on a phone's screen.
    Future<void> pumpReader(WidgetTester tester, {String? questionId}) async {
      tester.view.physicalSize = const Size(360, 690);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(questionId: questionId));
      await tester.pumpAndSettle();
    }

    /// Lets a toast run its course.
    Future<void> waitOutToast(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }

    /// The button saying [label] in the dialog that asks first.
    Finder inDialog(String label) => find.descendant(
          of: find.byType(ConfirmDialogMolecule),
          matching: find.widgetWithText(AppButtonAtom, label),
        );

    /// Opens the reader on the student's own question, shared with Sam.
    Future<void> pumpSharedWithSam(WidgetTester tester) async {
      repository.sharedWith = [
        {'friend_id': '7', 'nickname': 'Sam'},
      ];
      sharing.sharedWith[ownQuestionId] = [sam];
      await pumpReader(tester, questionId: ownQuestionId);
    }

    testWidgets('Share lists the friends, and Send shares with those ticked',
        (tester) async {
      await pumpReader(tester, questionId: ownQuestionId);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(find.text('Share with friends'), findsOneWidget);
      expect(find.text('Friends will see your photo and the full solution'),
          findsOneWidget);
      await tester.tap(find.text('Kate'));
      await tester.pump();
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(sharing.calls, ['loadFriends', 'share $ownQuestionId 13']);
      expect(find.text('Share with friends'), findsNothing);
      expect(find.text('Question shared.'), findsOneWidget);
      expect(find.text('Shared with Kate'), findsOneWidget);
      await waitOutToast(tester);
    });

    testWidgets(
        'a share that answers as its sheet closes leaves the reader open',
        (tester) async {
      tester.view.physicalSize = const Size(360, 690);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: '/saved/$ownQuestionId/solution',
        routes: [
          GoRoute(
            path: '/saved',
            builder: (_, __) => const Scaffold(body: Text('Saved page')),
            routes: [
              GoRoute(
                path: ':questionId/solution',
                builder: (_, state) => QuestionSolutionPage(
                  questionId: state.pathParameters['questionId'],
                  tabLocation: '/saved',
                  tabName: 'Saved',
                ),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) =>
            MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kate'));
      await tester.pump();
      final answer = sharing.hold = Completer<void>();
      await tester.tap(find.text('Send'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('share_close')));
      // The sheet takes 200ms to close. The share answers halfway through.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      answer.complete();
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path,
          '/saved/$ownQuestionId/solution');
      expect(find.text('Saved page'), findsNothing);
      expect(find.text('Shared with Kate'), findsOneWidget);
      await waitOutToast(tester);
    });

    testWidgets(
        'a question already shared says who with, and Stop sharing asks first',
        (tester) async {
      repository.sharedWith = [
        {'friend_id': '7', 'nickname': 'Sam'},
      ];
      sharing.sharedWith[ownQuestionId] = [sam];
      await pumpReader(tester, questionId: ownQuestionId);
      expect(find.text('Shared with Sam'), findsOneWidget);

      await tester.tap(find.text('Stop sharing'));
      await tester.pumpAndSettle();
      expect(find.text('Stop sharing?'), findsOneWidget);
      expect(find.text("Your friends won't see this question any more."),
          findsOneWidget);
      await tester.tap(find.descendant(
        of: find.byType(ConfirmDialogMolecule),
        matching: find.widgetWithText(AppButtonAtom, 'Stop sharing'),
      ));
      await tester.pumpAndSettle();

      expect(sharing.calls, ['stopSharing $ownQuestionId']);
      expect(find.text('Stopped sharing.'), findsOneWidget);
      expect(find.text('Shared with Sam'), findsNothing);
      expect(find.text('Share'), findsOneWidget);
      await waitOutToast(tester);
    });

    testWidgets('a refused Send says why, and keeps the sheet open and ticked',
        (tester) async {
      sharing.failNext['share'] = RefusedFailure(
          429, "You've done that a lot today. Try again tomorrow.");
      await pumpReader(tester, questionId: ownQuestionId);

      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kate'));
      await tester.pump();
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(sharing.calls, ['loadFriends', 'share $ownQuestionId 13']);
      expect(find.text("You've done that a lot today. Try again tomorrow."),
          findsOneWidget);
      expect(find.text('Share with friends'), findsOneWidget);
      final kate = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'Kate'),
      );
      expect(kate.value, isTrue, reason: 'Send again can share with Kate');
      expect(find.text('Shared with Kate'), findsNothing);
      await waitOutToast(tester);
    });

    testWidgets('a failed Stop sharing says why, and leaves the line as it was',
        (tester) async {
      sharing.failNext['stopSharing'] =
          NetworkFailure("We couldn't stop sharing. Try again.");
      await pumpSharedWithSam(tester);

      await tester.tap(find.text('Stop sharing'));
      await tester.pumpAndSettle();
      await tester.tap(inDialog('Stop sharing'));
      await tester.pumpAndSettle();

      expect(sharing.calls, ['stopSharing $ownQuestionId']);
      expect(find.text("We couldn't stop sharing. Try again."), findsOneWidget);
      expect(find.text('Shared with Sam'), findsOneWidget);
      expect(find.text('Stop sharing'), findsOneWidget);
      await waitOutToast(tester);
    });

    testWidgets('Cancel on Stop sharing sends nothing', (tester) async {
      await pumpSharedWithSam(tester);

      await tester.tap(find.text('Stop sharing'));
      await tester.pumpAndSettle();
      await tester.tap(inDialog('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Stop sharing?'), findsNothing);
      expect(sharing.calls, isEmpty);
      expect(find.text('Shared with Sam'), findsOneWidget);
    });

    testWidgets('the sample offers no Share', (tester) async {
      await pumpReader(tester);

      expect(find.byKey(const Key('solution_briefing')), findsOneWidget);
      expect(find.text('Share'), findsNothing);
    });
  });

  group('a question a friend shared', () {
    late _RecordingRepository repository;
    late FakeQuestionSharingRepository sharing;

    setUp(() async {
      await serviceLocator.reset();
      repository = _RecordingRepository()
        ..sharedBy = {'friend_id': '7', 'nickname': 'Sam'};
      sharing = FakeQuestionSharingRepository();
      _registerReader(repository, sharing: sharing);
    });

    /// Opens Sam's question 301 from Saved, on a phone's screen. Solve is
    /// there too, where Ask another question goes.
    Future<GoRouter> pumpFriendQuestion(WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 690);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: '/saved/301/solution',
        routes: [
          GoRoute(
            path: '/questions/photo',
            builder: (_, __) => const Scaffold(body: Text('Solve page')),
          ),
          GoRoute(
            path: '/saved',
            builder: (_, __) => const Scaffold(body: Text('Saved page')),
            routes: [
              GoRoute(
                path: ':questionId/solution',
                builder: (_, state) => QuestionSolutionPage(
                  questionId: state.pathParameters['questionId'],
                  tabLocation: '/saved',
                  tabName: 'Saved',
                ),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp.router(
          theme: AppTheme.dark,
          routerConfig: router,
        ),
      ));
      await tester.pumpAndSettle();
      return router;
    }

    /// Lets a toast run its course.
    Future<void> waitOutToast(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }

    /// The button saying [label] in the dialog that asks first.
    Finder inDialog(String label) => find.descendant(
          of: find.byType(ConfirmDialogMolecule),
          matching: find.widgetWithText(AppButtonAtom, label),
        );

    /// Reads Sam's question to the end and opens its answer, so the button
    /// under it says Ask another question, which goes to Solve.
    Future<void> readToTheAnswer(WidgetTester tester) async {
      final outcome = await _AssetRepository().loadSampleSolution();
      await _revealTheAnswer(tester, outcome.solution!.steps.length);
      await tester.pumpAndSettle();
      expect(find.text('Ask another question'), findsOneWidget);
    }

    /// Reports Sam for bullying, and waits for the answer, whatever it is.
    Future<void> trySendingReport(WidgetTester tester) async {
      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bullying or being mean'));
      await tester.pump();
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
    }

    /// Reports Sam for bullying, and waits for the sheet's thanks.
    Future<void> sendReport(WidgetTester tester) async {
      await trySendingReport(tester);
      expect(find.text('Thanks. The Doormer team will look at this.'),
          findsOneWidget);
    }

    /// Reports Sam for bullying, and opens Block's dialog once the report
    /// is sent.
    Future<void> reportThenAskToBlock(WidgetTester tester) async {
      await sendReport(tester);
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();
      expect(find.text('Block Sam?'), findsOneWidget);
    }

    testWidgets('says who shared it, with Remove and Report, and no Share',
        (tester) async {
      await pumpFriendQuestion(tester);

      expect(find.text('Shared by Sam'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
      expect(find.text('Report'), findsOneWidget);
      expect(find.text('Share'), findsNothing);
      expect(find.byType(BlocProvider<FriendQuestionBloc>), findsOneWidget);
      expect(find.byType(BlocProvider<ShareQuestionBloc>), findsNothing);
    });

    testWidgets(
        'opening its answer earns nothing: reveal-answer is never asked',
        (tester) async {
      final outcome = await _AssetRepository().loadSampleSolution();
      await pumpFriendQuestion(tester);

      await _revealTheAnswer(tester, outcome.solution!.steps.length);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('vault_revealed')), findsOneWidget);
      expect(repository.revealedIds, isEmpty);
    });

    testWidgets(
        'Remove asks first, then takes it out of Shared with me and goes back '
        'to Saved', (tester) async {
      final router = await pumpFriendQuestion(tester);

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(find.text('Remove this question?'), findsOneWidget);
      expect(
        find.text('It leaves your Shared with me list. Only Sam can share it '
            'with you again.'),
        findsOneWidget,
      );
      await tester.tap(inDialog('Remove'));
      await tester.pumpAndSettle();

      expect(sharing.calls, ['removeSharedQuestion 301']);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/saved');
      expect(find.text('Question removed.'), findsOneWidget);
      await waitOutToast(tester);
    });

    testWidgets(
        'Report sends the question with it, and offers Block only once sent; '
        'Block asks, then goes back to Saved', (tester) async {
      final router = await pumpFriendQuestion(tester);

      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      expect(find.text('Report Sam'), findsOneWidget);
      expect(find.text('Block'), findsNothing,
          reason: 'a block would end the share before the report is sent');
      await tester.tap(find.text('Bullying or being mean'));
      await tester.pump();
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      expect(find.text('Thanks. The Doormer team will look at this.'),
          findsOneWidget);
      expect(sharing.calls, ['reportSharedQuestion 7 301 bullying ']);
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();
      expect(find.text('Block Sam?'), findsOneWidget);
      expect(
        find.text("They won't see your cards or anything you shared, and "
            "their requests won't reach you. They won't be told."),
        findsOneWidget,
      );
      await tester.tap(inDialog('Block'));
      await tester.pumpAndSettle();

      expect(sharing.calls.last, 'blockFriend 7');
      expect(router.routerDelegate.currentConfiguration.uri.path, '/saved');
    });

    testWidgets(
        'a report that was sent stays sent: Report again shows Thanks and '
        'Block, not a new form', (tester) async {
      await pumpFriendQuestion(tester);
      await sendReport(tester);
      await tester.tap(find.byKey(const Key('report_close')));
      await tester.pumpAndSettle();
      expect(find.text('Report Sam'), findsNothing);

      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();

      expect(find.text('Thanks. The Doormer team will look at this.'),
          findsOneWidget);
      expect(find.text('Block'), findsOneWidget);
      expect(find.text('Send report'), findsNothing);
      expect(sharing.calls, ['reportSharedQuestion 7 301 bullying ']);
    });

    testWidgets(
        'a Block that fails can be tried again from Report, with no second '
        'report', (tester) async {
      final router = await pumpFriendQuestion(tester);
      await reportThenAskToBlock(tester);
      sharing.failNext['blockFriend'] =
          NetworkFailure("We couldn't block that student. Try again.");
      await tester.tap(inDialog('Block'));
      await tester.pumpAndSettle();
      expect(find.text('Report Sam'), findsNothing,
          reason: 'the sheet closes once Block is confirmed');
      expect(find.text("We couldn't block that student. Try again."),
          findsOneWidget);
      await waitOutToast(tester);

      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      expect(find.text('Thanks. The Doormer team will look at this.'),
          findsOneWidget);
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();
      await tester.tap(inDialog('Block'));
      await tester.pumpAndSettle();

      expect(sharing.calls, [
        'reportSharedQuestion 7 301 bullying ',
        'blockFriend 7',
        'blockFriend 7',
      ]);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/saved');
    });

    testWidgets(
        'a sheet reopened while its report is on its way shows it being sent, '
        'then Thanks and Block', (tester) async {
      await pumpFriendQuestion(tester);
      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bullying or being mean'));
      await tester.pump();
      final answer = sharing.hold = Completer<void>();
      await tester.tap(find.text('Send report'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('report_close')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Report Sam'), findsNothing);

      await tester.tap(find.text('Report'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final sheet = find.byType(ReportSheetOrganism);
      expect(sheet, findsOneWidget);
      expect(find.text('Send report'), findsNothing,
          reason: 'it spins while the report is on its way');
      expect(
        find.descendant(
          of: sheet,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      answer.complete();
      await tester.pumpAndSettle();

      expect(find.text('Thanks. The Doormer team will look at this.'),
          findsOneWidget);
      expect(find.text('Block'), findsOneWidget);
      expect(sharing.calls, ['reportSharedQuestion 7 301 bullying ']);
    });

    testWidgets(
        'a report refused for the day (429) says why, and offers Block, which '
        'asks, then blocks and goes back to Saved', (tester) async {
      final router = await pumpFriendQuestion(tester);
      sharing.failNext['reportSharedQuestion'] = RefusedFailure(
          429, "You've done that a lot today. Try again tomorrow.");

      await trySendingReport(tester);
      expect(find.text("You've done that a lot today. Try again tomorrow."),
          findsOneWidget);
      // Waited out before the checks below, so a check that fails can't
      // leave the toast running into the next test.
      await waitOutToast(tester);
      expect(find.text('Thanks. The Doormer team will look at this.'),
          findsNothing);
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();
      expect(find.text('Block Sam?'), findsOneWidget);
      await tester.tap(inDialog('Block'));
      await tester.pumpAndSettle();

      expect(sharing.calls,
          ['reportSharedQuestion 7 301 bullying ', 'blockFriend 7']);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/saved');
    });

    testWidgets(
        'a report refused because the share has ended (404) says why, and '
        'offers Block', (tester) async {
      await pumpFriendQuestion(tester);
      sharing.failNext['reportSharedQuestion'] =
          RefusedFailure(404, "That question isn't shared with you any more.");

      await trySendingReport(tester);
      expect(find.text("That question isn't shared with you any more."),
          findsOneWidget);
      await waitOutToast(tester);

      expect(find.text('Block'), findsOneWidget);
    });

    testWidgets(
        'a report that fails with no connection says why, and keeps the form '
        'to send again, with no Block', (tester) async {
      await pumpFriendQuestion(tester);
      sharing.failNext['reportSharedQuestion'] =
          NetworkFailure("We couldn't send the report. Try again.");

      await trySendingReport(tester);
      expect(
          find.text("We couldn't send the report. Try again."), findsOneWidget);
      await waitOutToast(tester);

      expect(find.text('Send report'), findsOneWidget);
      expect(find.text('Block'), findsNothing);
    });

    testWidgets(
        'a removal that answers as the reader closes toward Solve leaves the '
        'student on Solve, and still says it is removed', (tester) async {
      final router = await pumpFriendQuestion(tester);
      await readToTheAnswer(tester);
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      final answer = sharing.hold = Completer<void>();
      await tester.tap(inDialog('Remove'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The reader takes 300ms to close. The removal answers halfway through.
      await tester.tap(find.text('Ask another question'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      answer.complete();
      await tester.pumpAndSettle();
      final landedOn = router.routerDelegate.currentConfiguration.uri.path;
      expect(find.text('Question removed.'), findsOneWidget);
      // Waited out before the checks below, so a check that fails can't leave
      // the toast running into the next test.
      await waitOutToast(tester);

      expect(sharing.calls, ['removeSharedQuestion 301']);
      expect(landedOn, '/questions/photo');
      expect(find.text('Solve page'), findsOneWidget);
    });

    testWidgets(
        'a block that answers as the reader closes toward Solve leaves the '
        'student on Solve', (tester) async {
      final router = await pumpFriendQuestion(tester);
      await readToTheAnswer(tester);
      await reportThenAskToBlock(tester);
      final answer = sharing.hold = Completer<void>();
      await tester.tap(inDialog('Block'));
      await tester.pumpAndSettle();
      expect(find.text('Report Sam'), findsNothing);

      // The reader takes 300ms to close. The block answers halfway through.
      await tester.tap(find.text('Ask another question'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      answer.complete();
      await tester.pumpAndSettle();

      expect(sharing.calls.last, 'blockFriend 7');
      expect(router.routerDelegate.currentConfiguration.uri.path,
          '/questions/photo');
      expect(find.text('Solve page'), findsOneWidget);
    });

    testWidgets(
        'a block that fails as the report sheet closes says why, and leaves '
        'the reader open', (tester) async {
      final router = await pumpFriendQuestion(tester);
      await reportThenAskToBlock(tester);
      final answer = sharing.hold = Completer<void>();
      sharing.failNext['blockFriend'] =
          RefusedFailure(404, "We couldn't find that student.");
      await tester.tap(inDialog('Block'));

      // The sheet takes a moment to close. The block fails as it does.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      answer.complete();
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path,
          '/saved/301/solution');
      expect(find.text('Report Sam'), findsNothing);
      expect(find.text('Shared by Sam'), findsOneWidget);
      expect(find.text("We couldn't find that student."), findsOneWidget);
      await waitOutToast(tester);
    });

    testWidgets('a removal that fails says why, and leaves the reader open',
        (tester) async {
      final router = await pumpFriendQuestion(tester);
      sharing.failNext['removeSharedQuestion'] =
          NetworkFailure("We couldn't remove that question. Try again.");

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      await tester.tap(inDialog('Remove'));
      await tester.pumpAndSettle();

      expect(sharing.calls, ['removeSharedQuestion 301']);
      expect(router.routerDelegate.currentConfiguration.uri.path,
          '/saved/301/solution');
      expect(find.text("We couldn't remove that question. Try again."),
          findsOneWidget);
      expect(find.text('Remove'), findsOneWidget,
          reason: 'the student can try again');
      await waitOutToast(tester);
    });

    testWidgets(
        'a removal that answers while the report sheet is open goes back to '
        'Saved, and takes the sheet with it', (tester) async {
      final router = await pumpFriendQuestion(tester);
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      final answer = sharing.hold = Completer<void>();
      await tester.tap(inDialog('Remove'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The sheet covers the reader, which is still open, when the removal
      // answers.
      await tester.tap(find.text('Report'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Report Sam'), findsOneWidget);
      answer.complete();
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, '/saved');
      expect(find.text('Report Sam'), findsNothing);
      expect(find.text('Question removed.'), findsOneWidget);
      await waitOutToast(tester);
    });

    testWidgets(
        'while a removal is on its way, Send report is off: the removal ends '
        'the share the report is about', (tester) async {
      await pumpFriendQuestion(tester);
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      final answer = sharing.hold = Completer<void>();
      await tester.tap(inDialog('Remove'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Report'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Bullying or being mean'));
      await tester.pump();

      expect(
        tester
            .widget<AppButtonAtom>(
                find.widgetWithText(AppButtonAtom, 'Send report'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Send report'));
      await tester.pump();
      expect(sharing.calls, ['removeSharedQuestion 301']);
      answer.complete();
      await tester.pumpAndSettle();
      await waitOutToast(tester);
    });
  });
}
