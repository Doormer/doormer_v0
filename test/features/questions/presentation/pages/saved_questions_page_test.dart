import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/domain/entity/daily_limit.dart';
import 'package:doormer/src/features/questions/domain/entity/shared_question_summary.dart';
import 'package:doormer/src/features/questions/domain/entity/shared_questions_page.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_question_summary.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_questions_page.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_solved_questions_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/saved_questions_bloc.dart';
import 'package:doormer/src/features/questions/presentation/organisms/photo_enlarge_organism.dart';
import 'package:doormer/src/features/questions/presentation/pages/ask_by_photo_page.dart';
import 'package:doormer/src/features/questions/presentation/pages/saved_questions_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../fake_question_sharing_repository.dart';

/// Tuesday 6 October 2026, 8pm, local time.
final _now = DateTime(2026, 10, 6, 20);

SolvedQuestionSummary _question(int id) => SolvedQuestionSummary(
      questionId: '$id',
      topic: 'Geometry - Area',
      method: 'Area by decomposition',
      questionText: 'Question $id text',
      askedAt: DateTime(2026, 10, 6, 9),
    );

/// Sam's question, asked late in September and shared yesterday.
final _samsQuestion = SharedQuestionSummary(
  question: SolvedQuestionSummary(
    questionId: '301',
    topic: 'Algebra - Simultaneous equations',
    method: 'Elimination',
    questionText: 'Solve 2x + y = 7 and x - y = 2.',
    askedAt: DateTime(2026, 9, 29, 9),
  ),
  sharedBy: sam,
  sharedAt: DateTime(2026, 10, 5, 18),
);

/// Plays the API. For each cursor it answers, in turn, with the pages or
/// failures queued for it; the last answer repeats. It remembers every cursor
/// it was asked for.
class _ScriptedRepository implements QuestionsRepository {
  final Map<String?, List<Object>> answers;
  final List<String?> cursors = [];

  _ScriptedRepository(this.answers);

  @override
  Future<SolvedQuestionsPage> loadSolvedQuestions({String? cursor}) async {
    cursors.add(cursor);
    final queue = answers[cursor];
    if (queue == null || queue.isEmpty) {
      throw StateError('no answer for cursor $cursor');
    }
    final answer = queue.length > 1 ? queue.removeAt(0) : queue.first;
    if (answer is SolvedQuestionsPage) return answer;
    throw answer;
  }

  @override
  Future<DailyLimit> loadDailyLimit() => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  setUpAll(AppLogger.disable);

  late _ScriptedRepository repository;
  late FakeQuestionSharingRepository sharing;
  late GoRouter router;

  void registerBloc() {
    serviceLocator.registerFactory<SavedQuestionsBloc>(
      () => SavedQuestionsBloc(
        loadSolvedQuestions: LoadSolvedQuestionsUseCase(repository),
      ),
    );
    sharing = FakeQuestionSharingRepository();
    registerQuestionSharingBlocs(sharing);
  }

  tearDown(() async {
    await serviceLocator.reset();
  });

  Future<void> pumpSaved(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    router = GoRouter(
      initialLocation: '/saved',
      routes: [
        GoRoute(
          path: '/saved',
          builder: (_, state) => SavedQuestionsPage(
            now: () => _now,
            isCovered: state.uri.path != '/saved',
          ),
          routes: [
            GoRoute(
              path: ':questionId/solution',
              builder: (_, state) => Scaffold(
                body: Text('Reader for ${state.pathParameters['questionId']}'),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/questions/photo',
          builder: (_, state) => Scaffold(
            body: Text(state.extra is ShowPhotoSourceOptionsOnOpen
                ? 'Solve page, photo options up'
                : 'Solve page'),
          ),
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
  }

  testWidgets('shows the solved questions', (tester) async {
    repository = _ScriptedRepository({
      null: [
        SolvedQuestionsPage(questions: [_question(42)])
      ],
    });
    registerBloc();

    await pumpSaved(tester);

    expect(find.text('Geometry · Area'), findsOneWidget);
    expect(find.text('Question 42 text'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets(
      'tapping a row opens its solution at its own address, under Saved',
      (tester) async {
    repository = _ScriptedRepository({
      null: [
        SolvedQuestionsPage(questions: [_question(42)])
      ],
    });
    registerBloc();
    await pumpSaved(tester);

    await tester.tap(find.text('Question 42 text'));
    await tester.pumpAndSettle();

    expect(find.text('Reader for 42'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path,
        '/saved/42/solution');
  });

  testWidgets('tapping the photo shows it full size, and Close comes back',
      (tester) async {
    repository = _ScriptedRepository({
      null: [
        SolvedQuestionsPage(questions: [_question(42)])
      ],
    });
    registerBloc();
    await pumpSaved(tester);

    await tester.tap(find.byKey(const Key('saved_question_photo')));
    await tester.pumpAndSettle();

    expect(find.byType(PhotoEnlargeOrganism), findsOneWidget);
    await tester.tap(find.byKey(const Key('enlarge_close')));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoEnlargeOrganism), findsNothing);
    expect(find.text('Question 42 text'), findsOneWidget);
  });

  testWidgets(
      'with nothing solved, Solve a question opens Solve with the photo '
      'options up', (tester) async {
    repository = _ScriptedRepository({
      null: [const SolvedQuestionsPage(questions: [])],
    });
    registerBloc();
    await pumpSaved(tester);

    await tester.tap(find.text('Solve a question'));
    await tester.pumpAndSettle();

    expect(find.text('Solve page, photo options up'), findsOneWidget);
  });

  testWidgets('a first page that fails offers Try again, which loads it',
      (tester) async {
    repository = _ScriptedRepository({
      null: [
        NetworkFailure("We couldn't connect."),
        SolvedQuestionsPage(questions: [_question(42)]),
      ],
    });
    registerBloc();
    await pumpSaved(tester);

    expect(find.text("We couldn't load your questions."), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Question 42 text'), findsOneWidget);
    expect(repository.cursors, [null, null]);
  });

  testWidgets('scrolling near the end loads the next page', (tester) async {
    repository = _ScriptedRepository({
      null: [
        SolvedQuestionsPage(
          questions: [for (var id = 40; id > 20; id--) _question(id)],
          nextCursor: '21',
        ),
      ],
      '21': [
        SolvedQuestionsPage(questions: [_question(20)]),
      ],
    });
    registerBloc();
    await pumpSaved(tester);

    await tester.drag(
        find.byKey(const Key('saved_question_list')), const Offset(0, -3000));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Question 20 text'),
      300,
      scrollable: find.descendant(
        of: find.byKey(const Key('saved_question_list')),
        matching: find.byType(Scrollable),
      ),
    );

    expect(find.text('Question 20 text'), findsOneWidget);
    expect(repository.cursors, [null, '21']);
  });

  group('Shared with me', () {
    setUp(() {
      repository = _ScriptedRepository({
        null: [
          SolvedQuestionsPage(questions: [_question(42)])
        ],
      });
      registerBloc();
      sharing.sharedPages = {
        null: SharedQuestionsPage(questions: [_samsQuestion]),
      };
    });

    Future<void> openSharedWithMe(WidgetTester tester) async {
      await tester.tap(find.text('Shared with me'));
      await tester.pumpAndSettle();
    }

    testWidgets('Mine shows first, and Shared with me loads only once opened',
        (tester) async {
      await pumpSaved(tester);

      expect(find.text('Question 42 text'), findsOneWidget);
      expect(sharing.calls, isEmpty);
      await openSharedWithMe(tester);

      expect(sharing.calls, ['loadSharedQuestions']);
      expect(find.text('Question 42 text'), findsNothing);
    });

    testWidgets(
        'lists what friends shared, with who shared it and when, and a row '
        'opens its reader under Saved', (tester) async {
      await pumpSaved(tester);
      await openSharedWithMe(tester);

      expect(find.text('Algebra · Simultaneous equations'), findsOneWidget);
      expect(find.text('Solve 2x + y = 7 and x - y = 2.'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('saved_question_sender')),
          matching: find.text('Sam'),
        ),
        findsOneWidget,
      );
      expect(find.text('Yesterday'), findsOneWidget,
          reason: 'when it was shared');
      expect(find.text('29 Sep'), findsNothing,
          reason: 'not when it was asked');
      await tester.tap(find.text('Solve 2x + y = 7 and x - y = 2.'));
      await tester.pumpAndSettle();

      expect(find.text('Reader for 301'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.uri.path,
          '/saved/301/solution');
    });

    testWidgets('with nothing shared, says how questions arrive',
        (tester) async {
      sharing.sharedPages = {null: const SharedQuestionsPage(questions: [])};
      await pumpSaved(tester);
      await openSharedWithMe(tester);

      expect(
        find.text('Nothing shared yet. When a friend sends you a question, it '
            'shows here.'),
        findsOneWidget,
      );
    });

    testWidgets('a list that fails to load offers Try again, which loads it',
        (tester) async {
      sharing.failNext['loadSharedQuestions'] =
          NetworkFailure("We couldn't load the questions shared with you.");
      await pumpSaved(tester);
      await openSharedWithMe(tester);

      expect(find.text("We couldn't load the questions shared with you."),
          findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Solve 2x + y = 7 and x - y = 2.'), findsOneWidget);
    });

    testWidgets(
        'reads the list again once a solution over Saved closes, so a '
        'question removed there is gone', (tester) async {
      await pumpSaved(tester);
      await openSharedWithMe(tester);
      await tester.tap(find.text('Solve 2x + y = 7 and x - y = 2.'));
      await tester.pumpAndSettle();

      // Removed from the reader.
      await sharing.removeSharedQuestion('301');
      router.go('/saved');
      await tester.pumpAndSettle();

      expect(find.text('Solve 2x + y = 7 and x - y = 2.'), findsNothing);
      expect(
        find.text('Nothing shared yet. When a friend sends you a question, it '
            'shows here.'),
        findsOneWidget,
      );
      expect(sharing.calls.where((call) => call == 'loadSharedQuestions'),
          hasLength(2));
    });

    testWidgets('switching back shows Mine as it was', (tester) async {
      await pumpSaved(tester);
      await openSharedWithMe(tester);

      await tester.tap(find.text('Mine'));
      await tester.pumpAndSettle();

      expect(find.text('Question 42 text'), findsOneWidget);
      expect(repository.cursors, [null], reason: 'Mine was not read again');
    });
  });
}
