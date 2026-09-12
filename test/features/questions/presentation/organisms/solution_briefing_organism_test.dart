import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_segment_order.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_briefing_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_briefing_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pump(SolutionBriefingParams params) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SolutionBriefingOrganism(params: params),
        ),
      ),
    ),
  );
}

SolutionBriefingParams _params({String note = ''}) {
  return SolutionBriefingParams(
    title: 'The plan',
    body: diagramFirstOrder(const [
      TextSolutionSegment('Use the road angle, then the rectangle width.'),
    ]),
    note: note,
    onEnlargeVisual: (_) {},
  );
}

void main() {
  testWidgets('shows the heading and the approach body', (tester) async {
    await tester.pumpWidget(_pump(_params()));
    await tester.pump();

    expect(find.byKey(const Key('solution_briefing')), findsOneWidget);
    expect(find.text('The plan'), findsOneWidget);
    expect(
      find.text('Use the road angle, then the rectangle width.'),
      findsOneWidget,
    );
  });

  testWidgets('shows the note as a caveat when one is present', (tester) async {
    await tester.pumpWidget(_pump(
      _params(note: 'The width is derived, not printed.'),
    ));
    await tester.pump();

    expect(find.byKey(const Key('solution_note')), findsOneWidget);
    expect(find.text('The width is derived, not printed.'), findsOneWidget);
  });

  testWidgets('leaves no caveat behind when the note is empty', (tester) async {
    await tester.pumpWidget(_pump(_params()));
    await tester.pump();

    expect(find.byKey(const Key('solution_note')), findsNothing);
  });

  testWidgets('never states how many steps are coming', (tester) async {
    await tester.pumpWidget(_pump(_params()));
    await tester.pump();

    expect(find.textContaining(' of '), findsNothing,
        reason: 'the trail is the only progress indicator');
  });
}
