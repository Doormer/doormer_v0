import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/molecules/saved_list_switch_molecule.dart';
import 'package:doormer/src/features/questions/presentation/params/saved_list_switch_params.dart';
import 'package:doormer/src/features/questions/presentation/params/saved_question_row_params.dart';
import 'package:doormer/src/features/questions/presentation/params/saved_questions_body_params.dart';
import 'package:doormer/src/features/questions/presentation/templates/saved_questions_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<SavedList>> _pump(
  WidgetTester tester,
  SavedQuestionsBodyParams body, {
  SavedList list = SavedList.mine,
}) async {
  tester.view.physicalSize = const Size(360, 690);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final chosen = <SavedList>[];
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: SavedQuestionsTemplate(
        listSwitch: SavedListSwitchParams(selected: list, onSelect: chosen.add),
        body: body,
      ),
    ),
  ));
  return chosen;
}

void main() {
  testWidgets('shows a spinner while loading', (tester) async {
    await _pump(tester, const SavedQuestionsLoadingParams());

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
            dayLabel: 'Today',
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

  // The nav bar already names the page, so Saved has no heading of its own.
  testWidgets('opens with Mine and Shared with me, clear of the status bar',
      (tester) async {
    tester.view.padding = const FakeViewPadding(top: 44);
    await _pump(tester, const SavedQuestionsLoadingParams());

    final switchTop = tester.getRect(find.byType(SavedListSwitchMolecule)).top;
    final textTops = tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        .map((text) => text.localToGlobal(Offset.zero).dy);
    expect(switchTop, greaterThanOrEqualTo(44),
        reason: 'nothing hides under the status bar');
    expect(textTops, everyElement(greaterThanOrEqualTo(switchTop)),
        reason: 'no heading sits above the switch');
  });

  testWidgets('asks for Shared with me when it is tapped', (tester) async {
    final chosen = await _pump(tester, const SavedQuestionsLoadingParams());

    await tester.tap(find.text('Shared with me'));

    expect(chosen, [SavedList.sharedWithMe]);
  });

  // On the web, the nav bar reads each tab out without saying which one is
  // selected, so the switch carries the page's name for a screen reader.
  testWidgets('names the page Saved for a screen reader', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, const SavedQuestionsLoadingParams());

    expect(tester.getSemantics(find.byType(SavedListSwitchMolecule)),
        containsSemantics(label: 'Saved'));
    semantics.dispose();
  });

  testWidgets('an empty Shared with me says how questions arrive',
      (tester) async {
    await _pump(
      tester,
      const SharedQuestionsEmptyParams(),
      list: SavedList.sharedWithMe,
    );

    expect(
      find.text('Nothing shared yet. When a friend sends you a question, it '
          'shows here.'),
      findsOneWidget,
    );
    expect(find.text('Solve a question'), findsNothing);
  });

  testWidgets('paints no background, so the app backdrop shows through',
      (tester) async {
    await _pump(tester, const SavedQuestionsLoadingParams());

    expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, isNull);
  });
}
