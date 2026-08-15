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
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/submit_photo_question_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_sample_solution_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/solution_reader_bloc.dart';
import 'package:doormer/src/features/questions/presentation/pages/ask_by_photo_page.dart';
import 'package:doormer/src/features/questions/presentation/pages/question_solution_page.dart';
import 'package:doormer/src/features/questions/presentation/templates/solution_reader_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeQuestionsRepository implements QuestionsRepository {
  _FakeQuestionsRepository({this.outcome, this.pending});

  PhotoQuestionSolveOutcome? outcome;
  Completer<PhotoQuestionSolveOutcome>? pending;
  int callCount = 0;

  @override
  Future<PhotoQuestionSolveOutcome> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
  }) async {
    callCount++;
    if (pending != null) {
      return pending!.future;
    }
    return outcome!;
  }

  @override
  Future<PhotoQuestionSolveOutcome> loadSampleSolution() {
    throw UnimplementedError();
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

  ElevatedButton submitButton(WidgetTester tester) {
    return tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Submit to solver'),
    );
  }

  testWidgets('renders the initial empty state with submit disabled',
      (tester) async {
    repository = _FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    );
    registerBloc();
    await pumpPage(tester);

    expect(find.text('Ask by Photo'), findsOneWidget);
    expect(find.text('Choose photo'), findsOneWidget);
    expect(find.text('JPEG or PNG · max 10 MB'), findsOneWidget);
    expect(find.text('Ready when the page is readable'), findsOneWidget);
    expect(submitButton(tester).onPressed, isNull);
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

  testWidgets('template owns one primary scaffold with onPrimary header text',
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
    expect(scaffold.backgroundColor, colorScheme.primary);

    final uploadHeading = tester.widget<Text>(find.text('Upload a photo'));
    expect(uploadHeading.style?.color, colorScheme.onPrimary);
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
    expect(find.byType(Image), findsOneWidget);
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
      find.widgetWithText(ElevatedButton, 'Submit to solver'),
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit to solver'));
    await tester.pump(); // dispatch AskByPhotoSubmitted
    await tester.pump(); // BlocConsumer rebuilds into the Loading state

    // While the solver call is in flight the page shows a busy spinner.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Solving your photo'), findsOneWidget);
    expect(repository.callCount, 1);

    pending.complete(_outcome(PhotoQuestionSolveStatus.solved));
    await tester.pump(); // Solved state -> listener fires GoRouter.go
    await tester.pump(const Duration(seconds: 1)); // route transition settles
    await tester.pump(); // BlocProvider dispatches SolutionReaderStarted and rebuilds

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
      find.widgetWithText(ElevatedButton, 'Submit to solver'),
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit to solver'));
    await tester.pump(); // dispatch AskByPhotoSubmitted
    await tester.pump(); // Loading
    await tester
        .pump(const Duration(milliseconds: 50)); // use case future resolves
    await tester.pump(); // BlocConsumer rebuilds into the Unreadable state

    expect(repository.callCount, 1);
    expect(find.byType(QuestionSolutionPage), findsNothing);
    expect(find.text('We could not read it'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Retake'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Type instead'), findsOneWidget);
  });
}
