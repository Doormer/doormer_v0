// Renders the real screens inside the real shell across the supported viewport
// range and fails on any layout exception (RenderFlex overflow, unbounded
// constraints, failed assertions).
//
// The scale clamp changes the ratio between the design canvas and the space
// actually available - on a wide window the canvas is 461x692 rather than
// 360x690 - so layouts that happened to fit at exactly 1:1 are not guaranteed
// to fit once clamped. These tests are what makes that guarantee.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/quest_profile.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_quest_profile_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_sample_solution_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/submit_photo_question_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/solution_reader_bloc.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_reader_presenter.dart';
import 'package:doormer/src/features/questions/presentation/pages/ask_by_photo_page.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_reader_params.dart';
import 'package:doormer/src/features/questions/presentation/templates/solution_reader_template.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_trail_organism.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeQuestionsRepository implements QuestionsRepository {
  @override
  Future<PhotoQuestionSolveOutcome> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
  }) =>
      Completer<PhotoQuestionSolveOutcome>().future;

  @override
  Future<PhotoQuestionSolveOutcome> loadSampleSolution() =>
      Completer<PhotoQuestionSolveOutcome>().future;

  @override
  Future<QuestProfile> loadQuestProfile() async => const QuestProfile(
        bankedXp: 120,
        streakDays: 3,
        topic: 'Geometry - Area',
        questionTitle: 'Road through a field',
      );
}

final Uint8List _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M8AAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
);

/// Viewports the app is expected to survive, from a small phone through to a
/// desktop monitor.
const Map<String, Size> _viewports = {
  'small phone': Size(320, 568),
  'iPhone 14': Size(390, 844),
  'large phone': Size(414, 896),
  'phone landscape': Size(844, 390),
  'tablet portrait': Size(768, 1024),
  'laptop': Size(1440, 900),
  'desktop': Size(1920, 1080),
};


const _solutionDocument = SolutionDocument(
  schemaVersion: '3.0',
  steps: [
    SolutionStep(
      title: 'Find the road slope',
      body: [TextSolutionSegment('Let theta be the angle of the road.')],
    ),
    SolutionStep(title: 'Scale the width', body: []),
  ],
  finalAnswer: FinalAnswer(
    body: [TextSolutionSegment('The paved area is 160 square metres.')],
  ),
);

void main() {
  setUpAll(AppLogger.disable);

  late AskByPhotoBloc bloc;

  tearDown(() async => serviceLocator.reset());

  Future<void> pumpAskByPhoto(WidgetTester tester, Size viewport,
      {Key? key}) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeQuestionsRepository();
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

    await tester.pumpWidget(
      MaterialApp(
        // A distinct key forces a fresh element tree when the same test pumps
        // several viewports in a row. Without it Flutter updates the existing
        // AskByPhotoPage in place, so its BlocProvider keeps the bloc built
        // during the previous iteration and the page stays in that state.
        key: key,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AskByPhotoPage(),
        builder: (context, child) => ResponsiveAppShell(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();
  }

  for (final entry in _viewports.entries) {
    testWidgets('ask by photo lays out cleanly on a ${entry.key}',
        (tester) async {
      await pumpAskByPhoto(tester, entry.value);
      expect(tester.takeException(), isNull);

      // The hero must be reachable, not pushed off the painted column.
      expect(find.text('UPLOAD & SOLVE'), findsOneWidget);
      final heroWidth = tester.getSize(find.text('UPLOAD & SOLVE')).width;
      expect(heroWidth, lessThanOrEqualTo(AppLayout.maxContentWidth));
    });

    testWidgets('the solve panels lay out cleanly on a ${entry.key}',
        (tester) async {
      await pumpAskByPhoto(tester, entry.value);

      bloc.add(AskByPhotoPhotoPicked(
        imageBytes: _pngBytes,
        fileName: 'algebra.png',
        mimeType: 'image/png',
      ));
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('algebra.png'), findsOneWidget);
    });
  }

  testWidgets('the app column never exceeds the readable maximum',
      (tester) async {
    await pumpAskByPhoto(tester, const Size(1920, 1080));

    final scaffold = tester.getSize(find.byType(Scaffold).first);
    expect(scaffold.width, AppLayout.maxContentWidth);
  });

  testWidgets('the UI does not zoom with the window', (tester) async {
    // The defect this guards was never an overflow - the layouts scroll, so
    // they absorbed it silently. It was that ScreenUtil scales linearly off the
    // viewport with no ceiling, so a phone design rendered on a desktop window
    // at 4x-5x. Two different symptoms are measured because the design system
    // mixes both kinds of sizing:
    //
    //   * `AppButtonAtom` pads with `18.w` but takes its label size from the
    //     theme, so unclamped it grew into a huge box around normal text.
    //   * `PhotoUploadPanelOrganism` sets `fontSize: 20.sp`, so its heading
    //     grew directly.
    final buttonWidths = <String, double>{};
    final headingHeights = <String, double>{};

    for (final entry in _viewports.entries) {
      await serviceLocator.reset();
      await pumpAskByPhoto(tester, entry.value, key: ValueKey(entry.key));

      // Measured on the atom rather than the Material button: `.icon`
      // constructors build a private FilledButton subclass, and `find.byType`
      // matches the exact runtime type.
      buttonWidths[entry.key] = tester
          .getSize(find.ancestor(
            of: find.text('UPLOAD & SOLVE'),
            matching: find.byType(AppButtonAtom),
          ))
          .width;

      bloc.add(AskByPhotoPhotoPicked(
        imageBytes: _pngBytes,
        fileName: 'algebra.png',
        mimeType: 'image/png',
      ));
      await tester.pump();
      await tester.pump();

      headingHeights[entry.key] =
          tester.getSize(find.text('Photo input')).height;
    }

    void expectNoZoom(String what, Map<String, double> measured) {
      final baseline = measured['iPhone 14']!;
      for (final entry in measured.entries) {
        final ratio = entry.value / baseline;
        expect(
          ratio,
          // The clamp allows scale 0.85-1.3 and the phone baseline sits at
          // 1.083, so anything genuinely clamped lands in 0.78-1.20.
          inInclusiveRange(0.75, 1.25),
          reason: '$what on a ${entry.key} measured '
              '${ratio.toStringAsFixed(2)}x its size on a phone. Sizing must '
              'stay inside the clamped scale band instead of tracking the '
              'window.',
        );
      }
    }

    // Heading first: it is sized purely by `20.sp` so it tracks the scale
    // exactly, whereas the button's width is mostly its theme-sized label and
    // only its padding scales, which damps the signal.
    expectNoZoom('The upload panel heading', headingHeights);
    expectNoZoom('The hero button', buttonWidths);
  });

  group('the solution reader holds its pinned layout on every viewport', () {
    Future<void> pumpReader(WidgetTester tester, Size viewport) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: SolutionReaderTemplate(
            params: SolutionReaderParams(
              content: solutionReaderContent(
                const SolutionReaderReady(document: _solutionDocument),
              ),
              onNext: () {},
              onBack: () {},
              onToggleRationale: () {},
              onRevealAnswer: () {},
              onTravelTo: (_) {},
              onEnlargeVisual: (_) {},
            ),
          ),
          builder: (context, child) => ResponsiveAppShell(
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();
    }

    for (final entry in _viewports.entries) {
      testWidgets('on a ${entry.key}', (tester) async {
        await pumpReader(tester, entry.value);
        expect(tester.takeException(), isNull);

        // The reader's whole design rests on the trail and the CTA staying put
        // while only the step body scrolls. A short window shrinks the vertical
        // scale to its floor, which is where that would give way first.
        final trailBottom =
            tester.getBottomLeft(find.byType(SolutionTrailOrganism)).dy;
        final scrollTop =
            tester.getTopLeft(find.byKey(const Key('solution_scroll'))).dy;
        final ctaTop =
            tester.getTopLeft(find.byKey(const Key('solution_cta'))).dy;

        expect(trailBottom, lessThanOrEqualTo(scrollTop));
        expect(ctaTop, greaterThan(scrollTop));

        // The CTA has to stay inside the painted column. Compared against the
        // column's own rect, not the raw viewport: the column is centred, so on
        // a wide window its coordinates are offset from the screen origin.
        final column = tester.getRect(find.byType(Scaffold).first);
        expect(column.width, lessThanOrEqualTo(AppLayout.maxContentWidth + 1));

        final cta = tester.getRect(find.byKey(const Key('solution_cta')));
        expect(cta.left, greaterThanOrEqualTo(column.left - 1));
        expect(cta.right, lessThanOrEqualTo(column.right + 1));
        expect(cta.bottom, lessThanOrEqualTo(column.bottom + 1));
      });
    }
  });
}
