import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
import 'package:doormer/src/core/routes/destination_routes.dart';
import 'package:doormer/src/core/routes/root_navigator_key.dart';
import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/collection/domain/entity/deck_progress.dart';
import 'package:doormer/src/features/collection/domain/repository/collection_repository.dart';
import 'package:doormer/src/features/collection/domain/usecase/draw_card_usecase.dart';
import 'package:doormer/src/features/collection/domain/usecase/load_collection_usecase.dart';
import 'package:doormer/src/features/collection/domain/usecase/load_decks_usecase.dart';
import 'package:doormer/src/features/collection/domain/usecase/shatter_copy_usecase.dart';
import 'package:doormer/src/features/collection/presentation/bloc/collection_bloc.dart';
import 'package:doormer/src/features/collection/presentation/pages/collection_page.dart';
import 'package:doormer/src/features/profile/domain/usecase/sign_out_usecase.dart';
import 'package:doormer/src/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:doormer/src/features/questions/data/model/photo_question_response_model.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_question_summary.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_questions_page.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_question_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_quark_balance_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_sample_solution_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_solved_questions_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/reveal_answer_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/submit_photo_question_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/saved_questions_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/solution_reader_bloc.dart';
import 'package:doormer/src/features/questions/presentation/pages/ask_by_photo_page.dart';
import 'package:doormer/src/features/questions/presentation/pages/question_solution_page.dart';
import 'package:doormer/src/features/questions/presentation/pages/saved_questions_page.dart';
import 'package:doormer/src/shared/design/atomic/atoms/cross_fade_indexed_stack_atom.dart';
import 'package:doormer/src/shared/design/atomic/organisms/navigation_bar_organism.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Never asked anything: the Solve page only opens here.
class _UnusedQuestionsRepository implements QuestionsRepository {
  @override
  Future<PhotoQuestionSolveOutcome> loadQuestion(String questionId) =>
      throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Never answers, so the collection stays on its loading screen - the screen
/// a switch to Cards lands on first.
class _PendingCollectionRepository implements CollectionRepository {
  @override
  Future<({int quarkBalance, List<DeckProgress> decks})> loadDecks() =>
      Completer<({int quarkBalance, List<DeckProgress> decks})>().future;

  // Nothing has been read, so nothing is remembered.
  @override
  ({int quarkBalance, List<DeckProgress> decks})? get lastDeckList => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Answers at once, with no decks and 600 quarks. Counts the reads.
class _ReadyCollectionRepository implements CollectionRepository {
  int reads = 0;

  @override
  Future<({int quarkBalance, List<DeckProgress> decks})> loadDecks() async {
    reads++;
    return (quarkBalance: 600, decks: const <DeckProgress>[]);
  }

  // Nothing has been read, so nothing is remembered.
  @override
  ({int quarkBalance, List<DeckProgress> decks})? get lastDeckList => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Never answers, so Saved stays on its loading screen - the screen a switch
/// to Saved lands on first.
class _PendingSavedQuestionsRepository implements QuestionsRepository {
  @override
  Future<SolvedQuestionsPage> loadSolvedQuestions({String? cursor}) =>
      Completer<SolvedQuestionsPage>().future;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Has nothing solved, so Saved shows its empty state and its Solve a question
/// button.
class _EmptySavedQuestionsRepository implements QuestionsRepository {
  @override
  Future<SolvedQuestionsPage> loadSolvedQuestions({String? cursor}) async =>
      const SolvedQuestionsPage(questions: []);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Has one solved question at first, and answers each read with whatever
/// [questions] holds by then. Counts the reads.
class _CountingSavedQuestionsRepository implements QuestionsRepository {
  List<SolvedQuestionSummary> questions = [_solved('1')];
  int reads = 0;

  @override
  Future<SolvedQuestionsPage> loadSolvedQuestions({String? cursor}) async {
    reads++;
    return SolvedQuestionsPage(questions: questions);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Fails the preload, then answers retry reads with one solved question.
class _FailsFirstSavedQuestionsRepository implements QuestionsRepository {
  int reads = 0;
  final Completer<SolvedQuestionsPage> retry = Completer<SolvedQuestionsPage>();

  @override
  Future<SolvedQuestionsPage> loadSolvedQuestions({String? cursor}) async {
    reads++;
    if (reads == 1) throw NetworkFailure();
    return retry.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

SolvedQuestionSummary _solved(String id) => SolvedQuestionSummary(
      questionId: id,
      topic: 'Topic $id',
      method: 'Method $id',
      questionText: 'Question $id',
      askedAt: DateTime.utc(2026, 10, 6),
    );

/// Plays the API for solutions and for Solve: every question loads as the
/// bundled sample, and a photo stays solving until the test completes
/// [solve]. Records what it was asked.
class _SolutionsRepository implements QuestionsRepository {
  final List<String> loadedIds = [];
  int photosSent = 0;

  /// The solve of the last photo sent. Made as the photo is sent, inside the
  /// test's fake time, so its answer arrives there: one made in `setUp`
  /// answers on the real event loop, which a pump never reaches.
  Completer<PhotoQuestionSolveOutcome>? solve;

  @override
  Future<PhotoQuestionSolveOutcome> loadQuestion(String questionId) async {
    loadedIds.add(questionId);
    return _bundledSolution(questionId);
  }

  @override
  Future<int> loadQuarkBalance() async => 128;

  @override
  Future<PhotoQuestionSolveOutcome> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
  }) {
    photosSent++;
    return (solve = Completer()).future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// A real, decodable 1x1 transparent PNG, for Solve's photo preview.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// The bundled sample solution, as the API sends it for [questionId].
PhotoQuestionSolveOutcome _bundledSolution(String questionId) {
  final json = jsonDecode(
    File('assets/mock/mock_question_response.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return PhotoQuestionResponseModel.fromJson({
    ...json,
    'question_id': questionId,
  }).toEntity();
}

class _FakeSessionService implements SessionService {
  @override
  Future<void> logout() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(AppLogger.disable);

  setUp(() {
    serviceLocator.registerFactory<AskByPhotoBloc>(
      () => AskByPhotoBloc(
        submitPhotoQuestionUseCase:
            SubmitPhotoQuestionUseCase(_UnusedQuestionsRepository()),
      ),
    );
    serviceLocator.registerFactory<SavedQuestionsBloc>(
      () => SavedQuestionsBloc(
        loadSolvedQuestions:
            LoadSolvedQuestionsUseCase(_PendingSavedQuestionsRepository()),
      ),
    );
    final collection = _PendingCollectionRepository();
    serviceLocator.registerFactory<CollectionBloc>(
      () => CollectionBloc(
        loadDecks: LoadDecksUseCase(collection),
        loadCollection: LoadCollectionUseCase(collection),
        drawCard: DrawCardUseCase(collection),
        shatterCopy: ShatterCopyUseCase(collection),
      ),
    );
    serviceLocator.registerLazySingleton<SessionService>(
      _FakeSessionService.new,
    );
    serviceLocator.registerFactory<ProfileBloc>(
      () => ProfileBloc(
        signOut: SignOutUseCase(serviceLocator<SessionService>()),
      ),
    );
  });

  tearDown(() async {
    await serviceLocator.reset();
  });

  Future<GoRouter> pumpDestinations(
    WidgetTester tester, {
    String initialLocation = '/questions/photo',
  }) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation,
      routes: destinationRoutes,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    return router;
  }

  int litDestination(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

  /// Lets a switch's cross-fade finish. A fade ends on the first frame after
  /// its duration, which is when the page left goes out of sight.
  Future<void> waitOutTheFade(WidgetTester tester) => tester.pump(
      CrossFadeIndexedStackAtom.duration + const Duration(milliseconds: 16));

  /// Goes back to [location] as the browser's Back button does, which is how
  /// a student closes a solution.
  Future<void> browserBackTo(GoRouter router, String location) async {
    await router.routeInformationProvider.didPushRouteInformation(
      RouteInformation(uri: Uri.parse(location)),
    );
  }

  // Cutting from one page to the next in a single frame reads as a jump.
  testWidgets('switching tabs cross-fades the pages', (tester) async {
    await pumpDestinations(tester);

    await tester.tap(find.byIcon(Icons.style_outlined));
    await tester.pump();
    await tester.pump(CrossFadeIndexedStackAtom.duration ~/ 2);

    expect(find.byType(AskByPhotoPage), findsOneWidget,
        reason: 'Solve is still fading out');
    expect(find.byType(CollectionPage), findsOneWidget);
    expect(find.byType(NavigationBarOrganism), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(NavigationBarOrganism),
        matching: find.byType(CrossFadeIndexedStackAtom),
      ),
      findsNothing,
      reason: 'only the pages fade; the bar stays still',
    );

    await waitOutTheFade(tester);
    expect(find.byType(AskByPhotoPage), findsNothing);
    expect(find.byType(CollectionPage), findsOneWidget);
  });

  testWidgets('a route change mid-fade carries on to its tab', (tester) async {
    final router = await pumpDestinations(tester);

    await tester.tap(find.byIcon(Icons.style_outlined));
    await tester.pump();
    await tester.pump(CrossFadeIndexedStackAtom.duration ~/ 2);

    await router.routeInformationProvider.didPushRouteInformation(
      RouteInformation(uri: Uri.parse('/saved')),
    );
    await tester.pump();
    await waitOutTheFade(tester);

    expect(find.byType(SavedQuestionsPage), findsOneWidget);
    expect(find.byType(CollectionPage), findsNothing);
    expect(find.byType(AskByPhotoPage), findsNothing);
    expect(litDestination(tester), AppDestination.saved.index);
    expect(find.byType(NavigationBarOrganism), findsOneWidget);
  });

  // The bar is the shell's, so a switch only swaps the page above it. When
  // each page drew its own bar, the old bar was torn down and a new one built
  // on every switch, and the lit item jumped instead of sliding.
  testWidgets('Solve and Cards swap in place under one bar that stays put',
      (tester) async {
    await pumpDestinations(tester);
    final bar = tester.getRect(find.byType(NavigationBarOrganism));
    expect(
      tester.getRect(find.byType(NavigationBar)).bottom,
      moreOrLessEquals(690 - 20.h),
      reason: 'with a margin under it, clear of the screen edge',
    );

    await tester.tap(find.byIcon(Icons.style_outlined));
    await tester.pump();
    await waitOutTheFade(tester);

    expect(find.byType(AskByPhotoPage), findsNothing);
    expect(find.byType(CollectionPage), findsOneWidget);
    expect(find.byType(NavigationBarOrganism), findsOneWidget);
    expect(tester.getRect(find.byType(NavigationBarOrganism)), bar);
    expect(litDestination(tester), AppDestination.cards.index);

    await tester.tap(find.byIcon(Icons.document_scanner_outlined));
    await tester.pump();
    await waitOutTheFade(tester);

    expect(find.byType(CollectionPage), findsNothing);
    expect(find.byType(AskByPhotoPage), findsOneWidget);
    expect(find.byType(NavigationBarOrganism), findsOneWidget);
    expect(tester.getRect(find.byType(NavigationBarOrganism)), bar);
    expect(litDestination(tester), AppDestination.solve.index);
  });

  testWidgets('Profile swaps in place', (tester) async {
    await pumpDestinations(tester);
    final bar = tester.getRect(find.byType(NavigationBarOrganism));

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pump();

    expect(find.text('More profile options are coming soon.'), findsOneWidget);
    expect(litDestination(tester), AppDestination.profile.index);
    expect(tester.getRect(find.byType(NavigationBarOrganism)), bar);
  });

  testWidgets('Saved swaps in place, with Saved lit', (tester) async {
    await pumpDestinations(tester);
    final bar = tester.getRect(find.byType(NavigationBarOrganism));

    await tester.tap(find.byIcon(Icons.bookmark_outline));
    await tester.pump();
    await waitOutTheFade(tester);

    expect(find.byType(AskByPhotoPage), findsNothing);
    expect(find.byType(SavedQuestionsPage), findsOneWidget);
    expect(tester.getRect(find.byType(NavigationBarOrganism)), bar);
    expect(litDestination(tester), AppDestination.saved.index);
  });

  // Rebuilding a page on every visit meant a blank page and a spinner each
  // time Saved was opened.
  group('coming back to a page', () {
    late _CountingSavedQuestionsRepository saved;

    setUp(() {
      saved = _CountingSavedQuestionsRepository();
      serviceLocator.unregister<SavedQuestionsBloc>();
      serviceLocator.registerFactory<SavedQuestionsBloc>(
        () => SavedQuestionsBloc(
          loadSolvedQuestions: LoadSolvedQuestionsUseCase(saved),
        ),
      );
    });

    testWidgets('shows it as it was left, with no spinner', (tester) async {
      await pumpDestinations(tester, initialLocation: '/saved');
      await tester.pumpAndSettle();
      final page = tester.element(find.byType(SavedQuestionsPage).first);

      await tester.tap(find.byIcon(Icons.document_scanner_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.bookmark_outline));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('Question 1'), findsOneWidget);
      expect(
        tester.element(find.byType(SavedQuestionsPage).first),
        same(page),
        reason: 'the page is kept, not built afresh',
      );
    });

    testWidgets('Saved quietly shows a question solved meanwhile on top',
        (tester) async {
      await pumpDestinations(tester, initialLocation: '/saved');
      await tester.pumpAndSettle();
      expect(saved.reads, 1);

      await tester.tap(find.byIcon(Icons.document_scanner_outlined));
      await tester.pumpAndSettle();
      saved.questions = [_solved('2'), _solved('1')];
      await tester.tap(find.byIcon(Icons.bookmark_outline));
      await tester.pumpAndSettle();

      expect(saved.reads, 2);
      expect(
        tester.getTopLeft(find.textContaining('Question 2')).dy,
        lessThan(tester.getTopLeft(find.textContaining('Question 1')).dy),
      );
    });
  });

  // A first visit used to land on a spinner while the page loaded.
  group('loaded before the first visit', () {
    late _CountingSavedQuestionsRepository saved;
    late _ReadyCollectionRepository collection;

    setUp(() {
      saved = _CountingSavedQuestionsRepository();
      serviceLocator.unregister<SavedQuestionsBloc>();
      serviceLocator.registerFactory<SavedQuestionsBloc>(
        () => SavedQuestionsBloc(
          loadSolvedQuestions: LoadSolvedQuestionsUseCase(saved),
        ),
      );
      collection = _ReadyCollectionRepository();
      serviceLocator.unregister<CollectionBloc>();
      serviceLocator.registerFactory<CollectionBloc>(
        () => CollectionBloc(
          loadDecks: LoadDecksUseCase(collection),
          loadCollection: LoadCollectionUseCase(collection),
          drawCard: DrawCardUseCase(collection),
          shatterCopy: ShatterCopyUseCase(collection),
        ),
      );
    });

    testWidgets('Saved and Cards load while Solve is shown', (tester) async {
      await pumpDestinations(tester);
      await tester.pumpAndSettle();

      expect(saved.reads, 1);
      expect(collection.reads, 1);
      expect(find.byType(SavedQuestionsPage), findsNothing,
          reason: 'loaded out of sight');
      expect(find.byType(CollectionPage), findsNothing);
    });

    testWidgets('the first visit to Saved opens on its questions',
        (tester) async {
      await pumpDestinations(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.bookmark_outline));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('Question 1'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(saved.reads, 2, reason: 'the first visit also refreshes quietly');
    });

    testWidgets('the first visit to Cards opens on the deck list',
        (tester) async {
      await pumpDestinations(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.style_outlined));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('0 decks'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(collection.reads, 2,
          reason: 'the first visit also refreshes quietly');
    });

    testWidgets('a load that failed out of sight is tried again on first visit',
        (tester) async {
      final saved = _FailsFirstSavedQuestionsRepository();
      serviceLocator.unregister<SavedQuestionsBloc>();
      serviceLocator.registerFactory<SavedQuestionsBloc>(
        () => SavedQuestionsBloc(
          loadSolvedQuestions: LoadSolvedQuestionsUseCase(saved),
        ),
      );

      await pumpDestinations(tester);
      await tester.pumpAndSettle();

      expect(saved.reads, 1);
      expect(find.text(SavedQuestionsBloc.couldNotLoad), findsNothing);

      await tester.tap(find.byIcon(Icons.bookmark_outline));
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      saved.retry.complete(SolvedQuestionsPage(questions: [_solved('1')]));
      await tester.pumpAndSettle();

      expect(find.textContaining('Question 1'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(saved.reads, 2);
    });
  });

  // Opening a solution used to replace the whole tabbed screen, so every tab
  // was built afresh on the way back: Saved reloaded at the top of its list,
  // and a photo still solving was lost.
  group('a solution', () {
    late _CountingSavedQuestionsRepository saved;
    late _SolutionsRepository solutions;
    late AskByPhotoBloc solveBloc;

    setUp(() {
      saved = _CountingSavedQuestionsRepository();
      serviceLocator.unregister<SavedQuestionsBloc>();
      serviceLocator.registerFactory<SavedQuestionsBloc>(
        () => SavedQuestionsBloc(
          loadSolvedQuestions: LoadSolvedQuestionsUseCase(saved),
        ),
      );
      solutions = _SolutionsRepository();
      serviceLocator.registerFactory<SolutionReaderBloc>(
        () => SolutionReaderBloc(
          loadSampleSolutionUseCase: LoadSampleSolutionUseCase(solutions),
          loadQuestionUseCase: LoadQuestionUseCase(solutions),
          loadQuarkBalanceUseCase: LoadQuarkBalanceUseCase(solutions),
          revealAnswerUseCase: RevealAnswerUseCase(solutions),
        ),
      );
      // Made when Solve is first built, inside the test's fake time, so the
      // solve's answer arrives there. The test drives this one instance.
      serviceLocator.unregister<AskByPhotoBloc>();
      serviceLocator.registerFactory<AskByPhotoBloc>(
        () => solveBloc = AskByPhotoBloc(
          submitPhotoQuestionUseCase: SubmitPhotoQuestionUseCase(solutions),
        ),
      );
    });

    testWidgets('a saved question opens its solution over the nav bar',
        (tester) async {
      final router = await pumpDestinations(tester, initialLocation: '/saved');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Question 1'));
      await tester.pumpAndSettle();

      expect(find.byType(QuestionSolutionPage), findsOneWidget);
      expect(find.byType(NavigationBarOrganism), findsNothing);
      expect(router.routerDelegate.currentConfiguration.uri.path,
          '/saved/1/solution');
      expect(solutions.loadedIds, ['1']);
    });

    testWidgets('closing it shows Saved as it was left, with no reload',
        (tester) async {
      saved.questions = [for (var id = 1; id <= 20; id++) _solved('$id')];
      final router = await pumpDestinations(tester, initialLocation: '/saved');
      await tester.pumpAndSettle();
      final unscrolledTop = tester.getTopLeft(find.text('Question 4')).dy;
      await tester.drag(find.text('Question 2'), const Offset(0, -200));
      await tester.pumpAndSettle();
      final page = tester.element(find.byType(SavedQuestionsPage));
      final cards =
          tester.element(find.byType(CollectionPage, skipOffstage: false));
      final rowTop = tester.getTopLeft(find.text('Question 4')).dy;
      expect(rowTop, lessThan(unscrolledTop), reason: 'the list scrolled');

      await tester.tap(find.text('Question 4'));
      await tester.pumpAndSettle();
      expect(find.byType(QuestionSolutionPage), findsOneWidget);
      await browserBackTo(router, '/saved');
      await tester.pumpAndSettle();

      expect(find.byType(QuestionSolutionPage), findsNothing);
      expect(tester.element(find.byType(SavedQuestionsPage)), same(page));
      expect(
        tester.element(find.byType(CollectionPage, skipOffstage: false)),
        same(cards),
        reason: 'every tab is kept, not only the one under the solution',
      );
      expect(tester.getTopLeft(find.text('Question 4')).dy, rowTop,
          reason: 'scrolled where it was');
      expect(saved.reads, 1, reason: 'no reload');
      expect(litDestination(tester), AppDestination.saved.index);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/saved');
    });

    testWidgets('starting on its address opens it over a loaded Saved',
        (tester) async {
      final router = await pumpDestinations(
        tester,
        initialLocation: '/saved/1/solution',
      );
      await tester.pumpAndSettle();

      expect(find.byType(QuestionSolutionPage), findsOneWidget);
      expect(find.byType(NavigationBarOrganism), findsNothing);
      expect(saved.reads, 1, reason: 'Saved loads under the solution');

      await browserBackTo(router, '/saved');
      await tester.pumpAndSettle();

      expect(find.text('Question 1'), findsOneWidget);
      expect(litDestination(tester), AppDestination.saved.index);
      expect(saved.reads, 1, reason: 'and shows at once, with no reload');
    });

    testWidgets(
        'a photo still solving keeps solving while a saved solution is open',
        (tester) async {
      final router = await pumpDestinations(tester);
      solveBloc
        ..add(AskByPhotoPhotoPicked(
          imageBytes: _png,
          fileName: 'question.png',
          mimeType: 'image/png',
        ))
        ..add(const AskByPhotoSubmitted());
      await tester.pump();
      await tester.pump();
      expect(solutions.photosSent, 1);

      // The solving view's clock ticks every second, so nothing settles while
      // a photo is solving: frames are pumped one at a time.
      await tester.tap(find.byIcon(Icons.bookmark_outline));
      await tester.pump();
      await waitOutTheFade(tester);
      await tester.tap(find.text('Question 1'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(QuestionSolutionPage), findsOneWidget);

      solutions.solve!.complete(_bundledSolution('9'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(router.routerDelegate.currentConfiguration.uri.path,
          '/saved/1/solution',
          reason: 'the finished solve waits for the return to Solve');

      await browserBackTo(router, '/saved');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byIcon(Icons.document_scanner_outlined));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(router.routerDelegate.currentConfiguration.uri.path,
          '/questions/photo/9/solution');
      expect(find.byType(QuestionSolutionPage), findsOneWidget);
      expect(solutions.photosSent, 1, reason: 'solved once, not lost');
      expect(solutions.loadedIds, ['1'],
          reason: "the solve's own solution is handed over, not loaded");
    });

    // go_router remembers each tab's last address. Under a solution, Saved's
    // is the solution's, so restoring it after the student left the solution
    // for another tab put that address back in the address bar, where a
    // refresh would open the solution again.
    testWidgets('a solution left for another tab does not come back with Saved',
        (tester) async {
      final router = await pumpDestinations(tester, initialLocation: '/saved');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Question 1'));
      await tester.pumpAndSettle();

      // What "Ask another question" does.
      router.go('/questions/photo');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.bookmark_outline));
      await tester.pumpAndSettle();

      expect(find.byType(QuestionSolutionPage), findsNothing);
      expect(find.text('Question 1'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/saved');
    });
  });

  testWidgets('tapping Solve while on Solve brings up the photo options',
      (tester) async {
    await pumpDestinations(tester);
    expect(find.text('Open camera'), findsNothing);

    await tester.tap(find.byIcon(Icons.document_scanner_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Open camera'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
  });

  group('from an empty Saved', () {
    setUp(() {
      serviceLocator.unregister<SavedQuestionsBloc>();
      serviceLocator.registerFactory<SavedQuestionsBloc>(
        () => SavedQuestionsBloc(
          loadSolvedQuestions:
              LoadSolvedQuestionsUseCase(_EmptySavedQuestionsRepository()),
        ),
      );
    });

    Future<void> pumpEmptySaved(WidgetTester tester) async {
      await pumpDestinations(tester, initialLocation: '/saved');
      await tester.pumpAndSettle();
    }

    // The button promises a solve, so a second tap on UPLOAD & SOLVE would be
    // one too many.
    testWidgets('Solve a question opens Solve with the photo options up',
        (tester) async {
      await pumpEmptySaved(tester);

      await tester.tap(find.text('Solve a question'));
      await tester.pumpAndSettle();

      expect(find.byType(AskByPhotoPage), findsOneWidget);
      expect(find.text('Open camera'), findsOneWidget);
      expect(find.text('Choose from gallery'), findsOneWidget);
    });

    // Solve is kept alive after the first time, so the second request reaches
    // a page that is already built.
    testWidgets('Solve a question brings them up again the second time',
        (tester) async {
      await pumpEmptySaved(tester);
      await tester.tap(find.text('Solve a question'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(180, 40));
      await tester.pumpAndSettle();
      expect(find.text('Open camera'), findsNothing);

      await tester.tap(find.byIcon(Icons.bookmark_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Solve a question'));
      await tester.pumpAndSettle();

      expect(find.text('Open camera'), findsOneWidget);
    });

    testWidgets('the Solve tab opens Solve without them', (tester) async {
      await pumpEmptySaved(tester);

      await tester.tap(find.byIcon(Icons.document_scanner_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(AskByPhotoPage), findsOneWidget);
      expect(find.text('Open camera'), findsNothing);
    });

    testWidgets('going back to Solve does not bring them up again',
        (tester) async {
      await pumpEmptySaved(tester);
      await tester.tap(find.text('Solve a question'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(180, 40));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.bookmark_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.document_scanner_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Open camera'), findsNothing);
    });
  });

  group('the bar on a wide window', () {
    // Mounted the way the app mounts it: inside the app shell, which caps and
    // centres the column. Handing the bar a raw window width instead measures
    // a size it is never given.
    Future<void> pumpMounted(WidgetTester tester, Size window) async {
      tester.view.physicalSize = window;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        navigatorKey: rootNavigatorKey,
        initialLocation: '/questions/photo',
        routes: destinationRoutes,
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
          builder: (context, child) =>
              ResponsiveAppShell(child: child ?? const SizedBox.shrink()),
        ),
      );
      await tester.pump();
    }

    NavigationBar bar(WidgetTester tester) =>
        tester.widget<NavigationBar>(find.byType(NavigationBar));

    for (final window in const <String, Size>{
      'laptop': Size(1440, 900),
      'desktop': Size(1920, 1080),
      'tablet portrait': Size(820, 1180),
      'tablet landscape': Size(1180, 820),
      'phone': Size(390, 844),
    }.entries) {
      testWidgets('names its destinations on a ${window.key}', (tester) async {
        await pumpMounted(tester, window.value);

        expect(
          bar(tester).labelBehavior,
          NavigationDestinationLabelBehavior.alwaysShow,
          reason: 'five unlabelled icons is a guessing game when there is '
              'room to just say what they are',
        );
        for (final name in const [
          'Saved',
          'AI Tutor',
          'Solve',
          'Cards',
          'Profile',
        ]) {
          expect(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.text(name),
            ),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  });
}
