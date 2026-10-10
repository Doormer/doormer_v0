// Widget (UI-layer) tests for the Ask by Photo screen.
//
// These pump the REAL AskByPhotoPage widget tree — its BlocConsumer, the upload
// and status panels, the enable/disable logic on the Submit button, and the
// GoRouter hand-off on a solved outcome — backed by the real AskByPhotoBloc and
// SubmitPhotoQuestionUseCase. Only the repository (network boundary) and,
// where a test exercises the picker path, the platform photo picker/preparer
// are substituted.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/domain/entity/answer_reward.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_questions_page.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/submit_photo_question_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_question_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_quark_balance_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_sample_solution_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/reveal_answer_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/solution_reader_bloc.dart';
import 'package:doormer/src/features/questions/presentation/molecules/photo_preview_molecule.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solving_progress_organism.dart';
import 'package:doormer/src/features/questions/presentation/pages/ask_by_photo_page.dart';
import 'package:doormer/src/features/questions/presentation/pages/camera_page.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/display_ad_atom.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:doormer/src/features/questions/presentation/pages/question_solution_page.dart';
import 'package:doormer/src/features/questions/presentation/templates/solution_reader_template.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_file_input.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_preparer.dart';
import 'package:doormer/src/features/questions/utils/photo/picked_photo_file.dart';
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
  String? lastContentType;

  @override
  Future<PhotoQuestionSolveOutcome> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
  }) async {
    callCount++;
    lastBytes = imageBytes;
    lastContentType = contentType;
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
  Future<PhotoQuestionSolveOutcome> loadQuestion(String questionId) {
    throw UnimplementedError();
  }

  @override
  Future<int> loadQuarkBalance() async => 120;

  @override
  Future<SolvedQuestionsPage> loadSolvedQuestions({String? cursor}) =>
      throw UnimplementedError();

  @override
  Future<AnswerReward> revealAnswer(String questionId) {
    throw UnimplementedError();
  }
}

class _FakePhotoFileInput implements PhotoFileInput {
  _FakePhotoFileInput({this.file, this.usesNativeCamera = false});

  PickedPhotoFile? file;
  Object? failure;
  final List<bool> pickedFromCamera = [];

  @override
  final bool usesNativeCamera;

  @override
  Future<PickedPhotoFile?> pick({required bool fromCamera}) async {
    pickedFromCamera.add(fromCamera);
    if (failure != null) throw failure!;
    return file;
  }
}

class _FakePhotoPreparer implements PhotoPreparer {
  _FakePhotoPreparer();

  PreparedPhoto? result;
  Object? failure;
  Completer<PreparedPhoto>? pending;
  final List<PickedPhotoFile> prepared = [];

  @override
  Future<PreparedPhoto> prepare(PickedPhotoFile file) async {
    prepared.add(file);
    if (failure != null) throw failure!;
    if (pending != null) return pending!.future;
    return result!;
  }
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
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

final _pickedHeic = PickedPhotoFile(
  bytes: Uint8List.fromList([0, 0, 0, 0x18, 0x66, 0x74, 0x79, 0x70]),
  name: 'IMG_1.HEIC',
  mimeType: 'image/heic',
);

final _preparedJpeg = PreparedPhoto(
  bytes: _pngBytes,
  fileName: 'IMG_1.jpg',
  width: 1,
  height: 1,
);

void main() {
  setUpAll(AppLogger.disable);

  late _FakeQuestionsRepository repository;
  late AskByPhotoBloc bloc;
  late _FakePhotoFileInput fileInput;
  late _FakePhotoPreparer preparer;

  void registerBloc() {
    bloc = AskByPhotoBloc(
      submitPhotoQuestionUseCase: SubmitPhotoQuestionUseCase(repository),
    );
    serviceLocator.registerFactory<AskByPhotoBloc>(() => bloc);
    serviceLocator.registerFactory<SolutionReaderBloc>(
      () => SolutionReaderBloc(
        loadSampleSolutionUseCase: LoadSampleSolutionUseCase(repository),
        loadQuestionUseCase: LoadQuestionUseCase(repository),
        loadQuarkBalanceUseCase: LoadQuarkBalanceUseCase(repository),
        revealAnswerUseCase: RevealAnswerUseCase(repository),
      ),
    );
    fileInput = _FakePhotoFileInput();
    preparer = _FakePhotoPreparer();
    serviceLocator.registerLazySingleton<PhotoFileInput>(() => fileInput);
    serviceLocator.registerLazySingleton<PhotoPreparer>(() => preparer);
  }

  tearDown(() async {
    await serviceLocator.reset();
  });

  GoRouter buildRouter({bool showPhotoSourceOptionsOnOpen = false}) {
    return GoRouter(
      initialLocation: '/questions/photo',
      routes: [
        GoRoute(
          path: '/questions/photo',
          builder: (_, __) => AskByPhotoPage(
            showPhotoSourceOptionsOnOpen: showPhotoSourceOptionsOnOpen,
          ),
        ),
        GoRoute(
          path: '/collection',
          builder: (_, __) => const Scaffold(body: Text('Cards page')),
        ),
        GoRoute(
          path: '/saved',
          builder: (_, __) => const Scaffold(body: Text('Saved page')),
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

  // Error states raise a toast that auto-closes after 4s. Left running, the
  // binding fails the test with "A Timer is still pending" once the tree is
  // disposed, so tests that trigger one drain it before finishing.
  Future<void> drainToasts(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    bool showPhotoSourceOptionsOnOpen = false,
  }) async {
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
          routerConfig: buildRouter(
            showPhotoSourceOptionsOnOpen: showPhotoSourceOptionsOnOpen,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> chooseFrom(WidgetTester tester, String source) async {
    await tester.tap(find.byIcon(Icons.document_scanner_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text(source));
    await tester.pump();
    await tester.pump();
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

  testWidgets('opened to solve straight away, it shows the photo options',
      (tester) async {
    repository = _FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    );
    registerBloc();

    await pumpPage(tester, showPhotoSourceOptionsOnOpen: true);
    await tester.pumpAndSettle();

    expect(find.text('Open camera'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
  });

  testWidgets('a gallery photo picked from the options it opened with is shown',
      (tester) async {
    repository = _FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    );
    registerBloc();
    fileInput.file = _pickedHeic;
    preparer.result = _preparedJpeg;
    await pumpPage(tester, showPhotoSourceOptionsOnOpen: true);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose from gallery'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(fileInput.pickedFromCamera, [false]);
    expect(find.text('IMG_1.jpg'), findsOneWidget);
  });

  testWidgets('opened as a tab, it waits for a tap before showing the options',
      (tester) async {
    repository = _FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    );
    registerBloc();

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('UPLOAD & SOLVE'), findsOneWidget);
    expect(find.text('Open camera'), findsNothing);
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
    expect(find.text('Change photo'), findsOneWidget);
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

  testWidgets('an unreadable file is refused with a friendly message',
      (tester) async {
    repository = _FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    );
    registerBloc();
    fileInput.file = _pickedHeic;
    preparer.failure = ValidationFailure(photoUnreadableMessage);
    await pumpPage(tester);

    await chooseFrom(tester, 'Choose from gallery');
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text(photoUnreadableMessage), findsOneWidget);
    expect(find.text('JPG, PNG or HEIC'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PhotoPreviewMolecule),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
    expect(submitButton(tester).onPressed, isNull);
    await drainToasts(tester);
  });

  testWidgets('a gallery photo is prepared, shown and sent as a JPEG',
      (tester) async {
    repository = _FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.unreadable),
    );
    registerBloc();
    fileInput.file = _pickedHeic;
    preparer.result = _preparedJpeg;
    await pumpPage(tester);

    await chooseFrom(tester, 'Choose from gallery');

    expect(fileInput.pickedFromCamera, [false]);
    expect(preparer.prepared.single.name, 'IMG_1.HEIC');
    expect(find.text('IMG_1.jpg'), findsOneWidget);
    expect(submitButton(tester).onPressed, isNotNull);

    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Submit to solver'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Submit to solver'));
    await tester.pump();
    await tester.pump();

    expect(repository.lastBytes, _preparedJpeg.bytes);
    expect(repository.lastContentType, 'image/jpeg');
  });

  testWidgets('while a photo is prepared, nothing can be picked or sent',
      (tester) async {
    repository = _FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    );
    registerBloc();
    fileInput.file = _pickedHeic;
    preparer.pending = Completer<PreparedPhoto>();
    await pumpPage(tester);

    await chooseFrom(tester, 'Choose from gallery');

    expect(find.text('Preparing your photo…'), findsOneWidget);
    expect(submitButton(tester).onPressed, isNull);

    await tester.tap(find.byIcon(Icons.document_scanner_outlined));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(
        find.text('Still preparing your photo. One moment.'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsNothing);

    preparer.pending!.complete(_preparedJpeg);
    await tester.pump();
    await tester.pump();
    expect(find.text('Preparing your photo…'), findsNothing);
    expect(find.text('IMG_1.jpg'), findsOneWidget);
    await drainToasts(tester);
  });

  testWidgets('a HEIC the converter cannot open keeps the earlier photo',
      (tester) async {
    repository = _FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    );
    registerBloc();
    await pumpPage(tester);
    await selectPhoto(tester);
    fileInput.file = _pickedHeic;
    preparer.failure = NetworkFailure(heicConverterUnavailableMessage);

    await tester.tap(find.widgetWithText(AppButtonAtom, 'Change photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text(heicConverterUnavailableMessage), findsOneWidget);
    expect(find.text('algebra.png'), findsOneWidget);
    expect(submitButton(tester).onPressed, isNotNull);
    await drainToasts(tester);
  });

  testWidgets('closing the chooser leaves things as they were', (tester) async {
    repository = _FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    );
    registerBloc();
    await pumpPage(tester);

    await chooseFrom(tester, 'Choose from gallery');

    expect(fileInput.pickedFromCamera, [false]);
    expect(preparer.prepared, isEmpty);
    expect(find.text('Ready to solve?'), findsOneWidget);
    await drainToasts(tester);
  });

  testWidgets("on a phone, the camera button opens the phone's camera app",
      (tester) async {
    repository = _FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    );
    registerBloc();
    serviceLocator.unregister<PhotoFileInput>();
    fileInput = _FakePhotoFileInput(file: _pickedHeic, usesNativeCamera: true);
    serviceLocator.registerLazySingleton<PhotoFileInput>(() => fileInput);
    preparer.result = _preparedJpeg;
    await pumpPage(tester);

    await chooseFrom(tester, 'Open camera');

    expect(fileInput.pickedFromCamera, [true]);
    expect(find.byType(CameraPage), findsNothing);
    expect(find.text('IMG_1.jpg'), findsOneWidget);
  });

  testWidgets('on a computer, the camera button opens the webcam page',
      (tester) async {
    repository = _FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    );
    registerBloc();
    await pumpPage(tester);

    await chooseFrom(tester, 'Open camera');
    await tester.pump(const Duration(milliseconds: 500));

    expect(fileInput.pickedFromCamera, isEmpty);
    expect(find.byType(CameraPage), findsOneWidget);
    // CameraPage reports the missing camera plugin with a snack bar.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
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

    // While the solver call is in flight, the solving view replaces the photo
    // panels: a spinner, the time so far and what the solver is doing.
    expect(find.byType(SolvingProgressOrganism), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Solving your photo'), findsOneWidget);
    expect(find.text("What's happening"), findsOneWidget);
    expect(find.byType(PhotoPreviewMolecule), findsNothing);
    expect(repository.callCount, 1);

    // The submitted photo must stay on screen for the whole solve. Regression
    // guard: AskByPhotoLoading used to drop the selection, so the screen fell
    // back to the "pick a file" placeholder while still claiming to be
    // solving that very photo.
    expect(
      find.descendant(
        of: find.byType(SolvingProgressOrganism),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
    expect(find.text('JPG, PNG or HEIC'), findsNothing);

    // Tests build without the AdSense IDs, like local builds: never an ad.
    await tester.pump(const Duration(seconds: 4));
    expect(find.byType(DisplayAdAtom), findsNothing);

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
    expect(find.widgetWithText(AppButtonAtom, 'Change photo'), findsOneWidget);
    expect(find.text('Type instead'), findsNothing);
  });

  testWidgets('Change photo offers the camera, not just files', (tester) async {
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

    // The photo now survives the failure, so Change photo lives with it in the
    // upload panel rather than being repeated in the recovery panel below.
    expect(find.widgetWithText(AppButtonAtom, 'Change photo'), findsOneWidget);
    await tester.ensureVisible(
      find.widgetWithText(AppButtonAtom, 'Change photo'),
    );
    await tester.tap(find.widgetWithText(AppButtonAtom, 'Change photo'));
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
      expect(find.widgetWithText(AppButtonAtom, 'Change photo'), findsOneWidget,
          reason:
              'exactly one Change photo: the status panel must not repeat the '
              'button the upload panel is already showing');
      expect(find.text('Type instead'), findsNothing);
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

      await tester
          .ensureVisible(find.widgetWithText(AppButtonAtom, 'Try again'));
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
      expect(
          find.widgetWithText(AppButtonAtom, 'Change photo'), findsOneWidget);
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
    // Not pumpAndSettle: the solving view's spinner animates for as long as
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

  testWidgets('the Cards action opens the collection', (tester) async {
    repository = _FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    );
    registerBloc();
    await pumpPage(tester);

    await tester.tap(find.byIcon(Icons.style_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Cards page'), findsOneWidget);
    expect(find.byType(AskByPhotoPage), findsNothing);
  });

  testWidgets('the Cards action stays on home mid-solve, and says why',
      (tester) async {
    // Leaving would lose the answer, and photographing the same question again
    // would then count as a repeat and pay nothing.
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

    await tester.tap(find.byIcon(Icons.style_outlined));
    // Not pumpAndSettle: the solving view's spinner animates for as long as
    // the solve runs. Toastification 3.x inserts the toast after a frame and
    // then animates it from zero height, so finders skip it until it has some.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Cards page'), findsNothing);
    expect(find.byType(AskByPhotoPage), findsOneWidget);
    expect(find.text('Still solving your last photo. One moment.'),
        findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      AppDestination.solve.index,
      reason: 'a refused tap must not leave Cards lit',
    );

    pending.complete(_outcome(PhotoQuestionSolveStatus.solved));
    await tester.pump();
    await tester.pump();
    await drainToasts(tester);
  });

  testWidgets('the Saved action opens the saved questions', (tester) async {
    repository = _FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    );
    registerBloc();
    await pumpPage(tester);

    await tester.tap(find.byIcon(Icons.bookmark_outline));
    await tester.pumpAndSettle();

    expect(find.text('Saved page'), findsOneWidget);
    expect(find.byType(AskByPhotoPage), findsNothing);
  });

  testWidgets('the Saved action stays on home mid-solve, and says why',
      (tester) async {
    // Leaving would lose the answer, and photographing the same question again
    // would then count as a repeat and pay nothing.
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

    await tester.tap(find.byIcon(Icons.bookmark_outline));
    // Not pumpAndSettle: the submit button's spinner animates for as long as
    // the solve runs. The toast is inserted after a frame and grows from zero.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Saved page'), findsNothing);
    expect(find.byType(AskByPhotoPage), findsOneWidget);
    expect(find.text('Still solving your last photo. One moment.'),
        findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      AppDestination.solve.index,
      reason: 'a refused tap must not leave Saved lit',
    );

    pending.complete(_outcome(PhotoQuestionSolveStatus.solved));
    await tester.pump();
    await tester.pump();
    await drainToasts(tester);
  });
}
