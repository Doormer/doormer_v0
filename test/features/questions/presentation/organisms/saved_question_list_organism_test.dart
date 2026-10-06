import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/organisms/saved_question_list_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/saved_question_row_params.dart';
import 'package:doormer/src/features/questions/presentation/params/saved_questions_body_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts how often the list asked for more, or for another try.
class _Calls {
  int loadMore = 0;
  int retry = 0;
}

SavedQuestionListParams _list(
  _Calls calls, {
  bool hasMore = true,
  bool isLoadingMore = false,
  bool loadMoreFailed = false,
}) =>
    SavedQuestionListParams(
      rows: [
        for (var i = 20; i >= 1; i--)
          SavedQuestionRowParams(
            title: 'Topic $i',
            detail: 'Question $i',
            askedLabel: 'Today',
            thumbnailUrl: null,
            onOpen: () {},
            onEnlargePhoto: () {},
          ),
      ],
      hasMore: hasMore,
      isLoadingMore: isLoadingMore,
      loadMoreFailed: loadMoreFailed,
      onLoadMore: () => calls.loadMore++,
      onRetryLoadMore: () => calls.retry++,
    );

Future<void> _pump(WidgetTester tester, SavedQuestionListParams params) async {
  tester.view.physicalSize = const Size(360, 690);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: SavedQuestionListOrganism(params: params)),
    ),
  ));
}

const _listKey = Key('saved_question_list');

void main() {
  testWidgets('starts with the newest question at the top', (tester) async {
    await _pump(tester, _list(_Calls()));

    expect(find.text('Topic 20'), findsOneWidget);
    expect(find.text('Topic 1'), findsNothing,
        reason: 'the oldest row is below the fold');
  });

  testWidgets('asks for more when scrolled near the end', (tester) async {
    final calls = _Calls();
    await _pump(tester, _list(calls));

    await tester.drag(find.byKey(_listKey), const Offset(0, -3000));
    await tester.pump();

    expect(calls.loadMore, greaterThan(0));
  });

  testWidgets('asks for nothing more once every row is loaded', (tester) async {
    final calls = _Calls();
    await _pump(tester, _list(calls, hasMore: false));

    await tester.drag(find.byKey(_listKey), const Offset(0, -3000));
    await tester.pump();

    expect(calls.loadMore, 0);
  });

  testWidgets(
      'shows a spinner at the end, and asks for nothing, while more loads',
      (tester) async {
    final calls = _Calls();
    await _pump(tester, _list(calls, isLoadingMore: true));

    await tester.drag(find.byKey(_listKey), const Offset(0, -3000));
    await tester.pump();

    expect(calls.loadMore, 0);
    expect(find.byKey(const Key('saved_question_list_loading_more')),
        findsOneWidget);
  });

  testWidgets('offers Try again after a page fails, instead of asking again',
      (tester) async {
    final calls = _Calls();
    await _pump(tester, _list(calls, loadMoreFailed: true));

    await tester.drag(find.byKey(_listKey), const Offset(0, -3000));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saved_question_list_retry')));

    expect(calls.retry, 1);
    expect(calls.loadMore, 0);
  });
}
