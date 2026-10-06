import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_question_summary.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_questions_page.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_solved_questions_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/saved_questions_bloc.dart';
import 'package:doormer/src/features/questions/presentation/organisms/photo_enlarge_organism.dart';
import 'package:doormer/src/features/questions/presentation/pages/ask_by_photo_page.dart';
import 'package:doormer/src/features/questions/presentation/pages/saved_questions_page.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Tuesday 6 October 2026, 8pm, local time.
final _now = DateTime(2026, 10, 6, 20);

SolvedQuestionSummary _question(int id) => SolvedQuestionSummary(
      questionId: '$id',
      topic: 'Geometry - Area',
      method: 'Area by decomposition',
      questionText: 'Question $id text',
      askedAt: DateTime(2026, 10, 6, 9),
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
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  setUpAll(AppLogger.disable);

  late _ScriptedRepository repository;
  late GoRouter router;

  void registerBloc() {
    serviceLocator.registerFactory<SavedQuestionsBloc>(
      () => SavedQuestionsBloc(
        loadSolvedQuestions: LoadSolvedQuestionsUseCase(repository),
      ),
    );
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
          builder: (_, __) => SavedQuestionsPage(now: () => _now),
        ),
        GoRoute(
          path: '/questions/photo',
          builder: (_, state) => Scaffold(
            body: Text(state.extra is ShowPhotoSourceOptionsOnOpen
                ? 'Solve page, photo options up'
                : 'Solve page'),
          ),
        ),
        GoRoute(
          path: '/questions/:questionId/solution',
          builder: (_, state) => Scaffold(
            body: Text('Reader for ${state.pathParameters['questionId']}'),
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

  testWidgets('shows the solved questions, with Saved lit', (tester) async {
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
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      AppDestination.saved.index,
    );
  });

  testWidgets('tapping a row opens its solution at its own address',
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
        '/questions/42/solution');
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
}
