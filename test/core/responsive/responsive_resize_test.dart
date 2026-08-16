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
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_sample_solution_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/submit_photo_question_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/solution_reader_bloc.dart';
import 'package:doormer/src/features/questions/presentation/pages/ask_by_photo_page.dart';
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
}
