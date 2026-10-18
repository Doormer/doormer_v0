import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/params/saved_question_row_params.dart';
import 'package:doormer/src/features/questions/presentation/params/saved_questions_body_params.dart';
import 'package:doormer/src/features/questions/presentation/templates/saved_questions_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, SavedQuestionsBodyParams body) async {
  tester.view.physicalSize = const Size(360, 690);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: SavedQuestionsTemplate(body: body),
    ),
  ));
}

void main() {
  testWidgets('shows the heading and a spinner while loading',
      (tester) async {
    await _pump(tester, const SavedQuestionsLoadingParams());

    expect(find.text('Saved'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the empty state, whose button calls back', (tester) async {
    var solves = 0;
    await _pump(tester, SavedQuestionsEmptyParams(onSolve: () => solves++));

    await tester.tap(find.text('Solve a question'));

    expect(solves, 1);
  });

  testWidgets('says why the questions could not load, with Try again',
      (tester) async {
    var retries = 0;
    await _pump(
      tester,
      SavedQuestionsErrorParams(
        message: "We couldn't load your questions.",
        onRetry: () => retries++,
      ),
    );

    expect(find.text("We couldn't load your questions."), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });

  testWidgets('shows the rows', (tester) async {
    await _pump(
      tester,
      SavedQuestionListParams(
        rows: [
          SavedQuestionRowParams(
            title: 'Geometry · Area',
            detail: 'Find the area of the paddock.',
            askedLabel: 'Today',
            thumbnailUrl: null,
            onOpen: () {},
            onEnlargePhoto: () {},
          ),
        ],
        hasMore: false,
        isLoadingMore: false,
        loadMoreFailed: false,
        onLoadMore: () {},
        onRetryLoadMore: () {},
      ),
    );

    expect(find.text('Geometry · Area'), findsOneWidget);
  });

  testWidgets('paints no background, so the app backdrop shows through',
      (tester) async {
    await _pump(tester, const SavedQuestionsLoadingParams());

    expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, isNull);
  });
}
