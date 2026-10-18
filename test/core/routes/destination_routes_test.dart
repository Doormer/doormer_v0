import 'dart:async';

import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
import 'package:doormer/src/core/routes/destination_routes.dart';
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
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_question_summary.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_questions_page.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_solved_questions_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/submit_photo_question_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/saved_questions_bloc.dart';
import 'package:doormer/src/features/questions/presentation/pages/ask_by_photo_page.dart';
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
