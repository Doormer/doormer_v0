// Widget (UI-layer) tests for the Ask by Photo screen.
//
// These pump the REAL AskByPhotoPage widget tree — its BlocConsumer, the upload
// and status panels, the enable/disable logic on the Submit button, and the
// GoRouter hand-off on a solved outcome — backed by the real AskByPhotoBloc and
// SubmitPhotoQuestionUseCase. Only the repository (network boundary) and the
// platform file picker are substituted: the picker result is simulated by
// dispatching AskByPhotoPhotoPicked, exactly as AskByPhotoPage._pickPhoto does.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/quest_profile.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/submit_photo_question_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_quest_profile_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_sample_solution_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/solution_reader_bloc.dart';
import 'package:doormer/src/features/questions/presentation/molecules/photo_preview_molecule.dart';
import 'package:doormer/src/features/questions/presentation/pages/ask_by_photo_page.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/features/questions/presentation/pages/question_solution_page.dart';
import 'package:doormer/src/features/questions/presentation/templates/solution_reader_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeQuestionsRepository implements QuestionsRepository {
  _FakeQuestionsRepository({this.outcome, this.pending, this.failure});

  PhotoQuestionSolveOutcome? outcome;
  Completer<PhotoQuestionSolveOutcome>? pending;
  Failure? failure;
  int callCount = 0;
  Uint8List? lastBytes;

  @override
  Future<PhotoQuestionSolveOutcome> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
  }) async {
    callCount++;
    lastBytes = imageBytes;
    if (failure != null) {
      throw failure!;
    }
    if (pending != null) {
      return pending!.future;
    }
    return outcome!;
  }

  @override
  Future<PhotoQuestionSolveOutcome> loadSampleSolution() {
    throw UnimplementedError();
  }

  @override
  Future<QuestProfile> loadQuestProfile() async => const QuestProfile(
        bankedXp: 120,
        streakDays: 3,
        topic: 'Geometry - Area',
        questionTitle: 'Road through a field',
      );
}

PhotoQuestionSolveOutcome _outcome(PhotoQuestionSolveStatus status) {
  return PhotoQuestionSolveOutcome(
    status: status,
    questionId: 'q_${status.name}',
    solution: status == PhotoQuestionSolveStatus.solved
        ? const SolutionDocument(
            schemaVersion: '1.0',
            steps: [
              SolutionStep(
                title: 'Step 1',
                body: [TextSolutionSegment('Read the question.')],
              ),
            ],
            finalAnswer: FinalAnswer(
              body: [MathSolutionSegment(latex: '42', alt: 'forty two')],
            ),
          )
        : null,
  );
}

// A real, decodable 1x1 transparent PNG so the in-tree Image.memory preview
// decodes without raising a FlutterError during the test.
final Uint8List _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M8AAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
);

void main() {
  setUpAll(AppLogger.disable);

  late _FakeQuestionsRepository repository;
  late AskByPhotoBloc bloc;

  void registerBloc() {
    bloc = AskByPhotoBloc(
      submitPhotoQuestionUseCase: SubmitPhotoQuestionUseCase(repository),
    );
    serviceLocator.registerFactory<AskByPhotoBloc>(() => bloc);
    serviceLocator.registerFactory<SolutionReaderBloc>(
      () => SolutionReaderBloc(
        loadSampleSolutionUseCase: LoadSampleSolutionUseCase(repository),
        loadQuestProfileUseCase: LoadQuestProfileUseCase(repository),
      ),
    );
  }

  tearDown(() async {
    await serviceLocator.reset();
  });

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/questions/photo',
      routes: [
        GoRoute(
          path: '/questions/photo',
          builder: (_, __) => const AskByPhotoPage(),
        ),
        GoRoute(
          path: '/questions/:questionId/solution',
          builder: (context, state) {
            final extra = state.extra;
            return QuestionSolutionPage(
              questionId: state.pathParameters['questionId'] ?? '',
              solvedState: extra is AskByPhotoSolved ? extra : null,
            );
          },
        ),
      ],
    );
  }

  // Error states raise a toast that auto-closes after 2s. Left running, the
  // binding fails the test with "A Timer is still pending" once the tree is
  // disposed, so tests that trigger one drain it before finishing.
  Future<void> drainToasts(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: buildRouter(),
        ),
      ),
    );
    await tester.pump();
  }

  // Simulates the platform picker callback. A BlocConsumer rebuild from a
  // stream-driven state change lands on the next frame, so two pumps are needed
  // for the new state to be reflected in the widget tree.
  Future<void> selectPhoto(
    WidgetTester tester, {
    String fileName = 'algebra.png',
    String? mimeType = 'image/png',
  }) async {
    bloc.add(AskByPhotoPhotoPicked(
      imageBytes: _pngBytes,
      fileName: fileName,
      mimeType: mimeType,
    ));
    await tester.pump();
    await tester.pump();
  }

  FilledButton submitButton(WidgetTester tester) {
    return tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Submit to solver'),
    );
  }

  testWidgets('renders the idle hero state with no solver panels',
      (tester) async {
    repository = _FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    );
    registerBloc();
    await pumpPage(tester);

    // The idle landing screen is a single-CTA hero: the upload and status
    // panels stay unmounted until there is a photo, a solve in flight, or a
    // recoverable failure.
    expect(find.text('Ready to solve?'), findsOneWidget);
    expect(find.text('Upload a photo'), findsOneWidget);
    expect(find.text('UPLOAD & SOLVE'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Submit to solver'), findsNothing);
    expect(find.text('Ready when the page is readable'), findsNothing);
  });

  testWidgets('Solve navigation action opens photo source options',
      (tester) async {
    repository = _FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    );
    registerBloc();
    await pumpPage(tester);

    await tester.tap(find.byIcon(Icons.document_scanner_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Open camera'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
  });

  testWidgets('template owns one scaffold and lets the app backdrop through',
      (tester) async {
    repository = _FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    );
    registerBloc();
    await pumpPage(tester);

    expect(find.byType(Scaffold), findsOneWidget);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final colorScheme =
        Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
    // The page used to paint itself primary. That colour is bounded by the
    // content column, so on a wide window it showed as a violet slab with the
    // app backdrop still visible either side of it.
    expect(scaffold.backgroundColor, isNull);

    // And because the header now sits on the surface rather than on primary,
    // it takes the surface's ink.
    final uploadHeading = tester.widget<Text>(find.text('Upload a photo'));
    expect(uploadHeading.style?.color, colorScheme.onSurface);
  });

  testWidgets('selecting a photo shows the preview and enables submit',
      (tester) async {
    repository = _FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    );
    registerBloc();
    await pumpPage(tester);

    await selectPhoto(tester);

    expect(find.text('algebra.png'), findsOneWidget);
    expect(find.text('Retake'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    // Scoped to the preview: the template also paints a decorative background
    // Image.asset, so a bare byType(Image) finder matches two widgets.
    expect(
      find.descendant(
        of: find.byType(PhotoPreviewMolecule),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
    expect(submitButton(tester).onPressed, isNotNull);
  });

  testWidgets(
      'submitting a solved photo shows loading then hands off to the '
      'solution route', (tester) async {
    final pending = Completer<PhotoQuestionSolveOutcome>();
    repository = _FakeQuestionsRepository(pending: pending);
    registerBloc();
    await pumpPage(tester);

    await selectPhoto(tester);

    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Submit to solver'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Submit to solver'));
    await tester.pump(); // dispatch AskByPhotoSubmitted
    await tester.pump(); // BlocConsumer rebuilds into the Loading state

    // While the solver call is in flight the page shows a busy spinner.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Solving your photo'), findsOneWidget);
    expect(repository.callCount, 1);

    // The submitted photo must stay on screen for the whole solve. Regression
    // guard: AskByPhotoLoading used to drop the selection, so the preview
    // collapsed back to the "pick a file" placeholder while the status panel
    // underneath still claimed to be solving that very photo.
    expect(find.text('algebra.png'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PhotoPreviewMolecule),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
    expect(find.text('JPEG or PNG · max 10 MB'), findsNothing);

    pending.complete(_outcome(PhotoQuestionSolveStatus.solved));
    await tester.pump(); // Solved state -> listener fires GoRouter.go
    await tester.pump(const Duration(seconds: 1)); // route transition settles
    await tester
        .pump(); // BlocProvider dispatches SolutionReaderStarted and rebuilds

    expect(find.byType(QuestionSolutionPage), findsOneWidget);
    expect(find.byType(SolutionReaderTemplate), findsOneWidget);
  });

  testWidgets('an unreadable outcome renders the recovery panel in place',
      (tester) async {
    repository = _FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.unreadable),
    );
    registerBloc();
    await pumpPage(tester);

    await selectPhoto(tester);

    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Submit to solver'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Submit to solver'));
    await tester.pump(); // dispatch AskByPhotoSubmitted
    await tester.pump(); // Loading
    await tester
        .pump(const Duration(milliseconds: 50)); // use case future resolves
    await tester.pump(); // BlocConsumer rebuilds into the Unreadable state

    expect(repository.callCount, 1);
    expect(find.byType(QuestionSolutionPage), findsNothing);
    expect(find.text('We could not read it'), findsOneWidget);
    // Retake moved up to sit with the photo, which now survives the failure;
    // the recovery panel keeps only the action the photo panel lacks.
    expect(find.widgetWithText(AppButtonAtom, 'Retake'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Type instead'), findsOneWidget);
  });

  testWidgets('Retake on the recovery panel offers the camera, not just files',
      (tester) async {
    repository = _FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.unreadable),
    );
    registerBloc();
    await pumpPage(tester);

    await selectPhoto(tester);

    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Submit to solver'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Submit to solver'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    // The photo now survives the failure, so Retake lives with it in the
    // upload panel rather than being repeated in the recovery panel below.
    expect(find.widgetWithText(AppButtonAtom, 'Retake'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButtonAtom, 'Retake'));
    await tester.pumpAndSettle();

    // The recovery copy tells the student to retake the shot, so this button
    // has to reach the camera. It used to jump straight to the file picker,
    // which cannot retake anything, while every other photo entry point on the
    // screen offered both sources.
    expect(find.text('Open camera'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
  });

  group('a failed solve does not throw the photo away', () {
    Future<void> failTheSolve(WidgetTester tester) async {
      await selectPhoto(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Submit to solver'));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('the preview survives a network failure and offers Try again',
        (tester) async {
      repository =
          _FakeQuestionsRepository(failure: NetworkFailure('No connection.'));
      registerBloc();
      await pumpPage(tester);
      await failTheSolve(tester);

      expect(find.byType(PhotoPreviewMolecule), findsOneWidget,
          reason: 'losing the preview here forces the student to find and '
              'pick the same file over again after a blip');
      // The retry is the upload panel's own button, relabelled - not a second
      // control competing with it.
      expect(find.widgetWithText(AppButtonAtom, 'Try again'), findsOneWidget);
      expect(find.text('Submit to solver'), findsNothing);
      expect(find.widgetWithText(AppButtonAtom, 'Retake'), findsOneWidget,
          reason: 'exactly one Retake: the status panel must not repeat the '
              'button the upload panel is already showing');
      await drainToasts(tester);
    });

    testWidgets('Try again resubmits the same bytes', (tester) async {
      repository =
          _FakeQuestionsRepository(failure: NetworkFailure('No connection.'));
      registerBloc();
      await pumpPage(tester);
      await failTheSolve(tester);
      expect(repository.callCount, 1);

      repository.failure = null;
      repository.outcome = _outcome(PhotoQuestionSolveStatus.solved);

      await tester.ensureVisible(find.widgetWithText(AppButtonAtom, 'Try again'));
      await tester.tap(find.widgetWithText(AppButtonAtom, 'Try again'));
      await tester.pump();
      await tester.pump();

      expect(repository.callCount, 2);
      expect(repository.lastBytes, _pngBytes,
          reason: 'the retry must send the photo already in hand, not an '
              'empty or re-picked one');
      await drainToasts(tester);
    });

    testWidgets('an unreadable photo stays on screen but offers no Try again',
        (tester) async {
      repository = _FakeQuestionsRepository(
        outcome: _outcome(PhotoQuestionSolveStatus.unreadable),
      );
      registerBloc();
      await pumpPage(tester);
      await failTheSolve(tester);

      expect(find.byType(PhotoPreviewMolecule), findsOneWidget,
          reason: 'the student should see which photo was rejected');
      expect(find.text('Try again'), findsNothing,
          reason: 'the same blurry bytes read as blurry every time');
      expect(find.text('Submit to solver'), findsOneWidget,
          reason: 'the button stays generic when a resend would not help');
      expect(find.widgetWithText(AppButtonAtom, 'Retake'), findsOneWidget);
    });
  });

  testWidgets('the Solve action does not open a picker mid-solve',
      (tester) async {
    // The upload panel already refuses to re-pick while a solve is running.
    // The nav bar used to stay live, so a photo picked mid-flight replaced the
    // preview and then the earlier photo's solution arrived and routed away -
    // the student ends up reading a solution for a photo they just replaced.
    final pending = Completer<PhotoQuestionSolveOutcome>();
    repository = _FakeQuestionsRepository(pending: pending);
    registerBloc();
    await pumpPage(tester);

    await selectPhoto(tester);
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Submit to solver'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Submit to solver'));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.document_scanner_outlined));
    // Not pumpAndSettle: the submit button's spinner animates for as long as
    // the solve runs, so nothing settles until it finishes.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Open camera'), findsNothing);
    expect(find.text('Choose from gallery'), findsNothing);

    pending.complete(_outcome(PhotoQuestionSolveStatus.solved));
    await tester.pump();
    await tester.pump();
    await drainToasts(tester);
  });
}
