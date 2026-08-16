// A desktop user drags a window edge; a phone user rotates. Both change the
// viewport after first paint, and ScreenUtil holds its metrics in a global
// singleton rather than in the widget tree - so reconfiguring it is only half
// the job. Anything already built has to be rebuilt too, or it keeps painting
// at the old scale until something unrelated happens to dirty it.
import 'dart:async';
import 'dart:typed_data';

import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
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
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// A screen that reads ScreenUtil once per build, the way real widgets do.
///
/// Deliberately public: ScreenUtilInit refuses to mark `_`-prefixed widgets
/// dirty on a metrics change, on the assumption they are framework internals,
/// so a private probe would report a false failure here.
class ScaledProbe extends StatelessWidget {
  const ScaledProbe({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          key: const Key('scaled'),
          width: 100.w,
          height: 20.h,
        ),
      ),
    );
  }
}

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

void main() {
  setUpAll(AppLogger.disable);
  tearDown(() async => serviceLocator.reset());

  testWidgets('resizing the window restyles what is already on screen',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 690);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: const ScaledProbe(),
        builder: (context, child) => ResponsiveAppShell(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();

    final atDesign = tester.getSize(find.byKey(const Key('scaled')));
    expect(atDesign.width, closeTo(100, 1));

    // Grow the window past the column cap. The scale should rise to its
    // ceiling and the already-mounted subtree should repaint at the new size.
    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();

    final atLaptop = tester.getSize(find.byKey(const Key('scaled')));
    expect(
      atLaptop.width,
      closeTo(100 * AppLayout.maxScale, 1),
      reason: 'the mounted subtree kept the scale it was first built with',
    );

    // And back down again.
    tester.view.physicalSize = const Size(360, 690);
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const Key('scaled'))).width,
      closeTo(100, 1),
    );
  });

  testWidgets('a real page reflows when the window is resized', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeQuestionsRepository();
    serviceLocator.registerFactory<AskByPhotoBloc>(
      () => AskByPhotoBloc(
        submitPhotoQuestionUseCase: SubmitPhotoQuestionUseCase(repository),
      ),
    );
    serviceLocator.registerFactory<SolutionReaderBloc>(
      () => SolutionReaderBloc(
        loadSampleSolutionUseCase: LoadSampleSolutionUseCase(repository),
        loadQuestProfileUseCase: LoadQuestProfileUseCase(repository),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: const AskByPhotoPage(),
        builder: (context, child) => ResponsiveAppShell(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Rect heroRect() => tester.getRect(find.ancestor(
          of: find.text('UPLOAD & SOLVE'),
          matching: find.byType(AppButtonAtom),
        ));

    final wide = heroRect();
    // Centred in a 1440px window, the 600px column starts at 420.
    expect(wide.center.dx, closeTo(720, 1));

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();

    final narrow = heroRect();
    expect(narrow.center.dx, closeTo(195, 1),
        reason: 'the column should re-centre on the narrowed window');
    expect(narrow.width, lessThan(wide.width),
        reason: 'padding should shrink with the scale rather than stay pinned '
            'to the size it was first built at');
  });

  // The solution reader is the screen that holds every private widget in the
  // app that reads ScreenUtil (`_TrailNode`, `_TrailConnector`, `_CtaBar`).
  // ScreenUtilInit refuses to mark `_`-prefixed elements dirty itself, so these
  // can only restyle via their public parent rebuilding and replacing them -
  // which would stop working the day one of them is constructed `const`.
  testWidgets('private widgets restyle through their parent on a resize',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
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
        builder: (context, child) =>
            ResponsiveAppShell(child: child ?? const SizedBox.shrink()),
      ),
    );
    await tester.pump();

    // The trail's own box is scale-independent (nodes cap at 44px, the
    // connector is a hard-coded 18). Its ScreenUtil reads are the glyphs
    // *inside* each node, so those are what has to be measured.
    Size nodeGlyph() => tester.getSize(
          find.descendant(
            of: find.byKey(const Key('trail_node_1')),
            matching: find.byType(Text),
          ),
        );

    final wideGlyph = nodeGlyph();
    // Not the CTA button: its height comes from the theme, not ScreenUtil.
    // `_CtaBar`'s own scale-driven part is the chevron on the Back control.
    Size ctaChevron() =>
        tester.getSize(find.byIcon(Icons.chevron_left_rounded));

    final wideCta = ctaChevron();

    tester.view.physicalSize = const Size(390, 844);
    await tester.pump();
    await tester.pump();

    final narrowGlyph = nodeGlyph();
    final narrowCta = ctaChevron();

    expect(narrowGlyph.height, lessThan(wideGlyph.height),
        reason: '_TrailNode draws its number at 14.sp, so the glyph must '
            'follow the scale down rather than stay at the 1.3x it was first '
            'built with');
    expect(narrowCta.height, lessThan(wideCta.height),
        reason: '_CtaBar draws its chevron at 17.sp and must follow too');
  });
}
