import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/molecules/saved_question_row_molecule.dart';
import 'package:doormer/src/features/questions/presentation/params/saved_question_row_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: Center(child: child)),
      ),
    );

SavedQuestionRowParams _row({
  String title = 'Geometry · Area',
  String detail = 'Find the area of the paddock.',
  VoidCallback? onOpen,
  VoidCallback? onEnlargePhoto,
}) =>
    SavedQuestionRowParams(
      title: title,
      detail: detail,
      askedLabel: 'Today',
      thumbnailUrl: null,
      onOpen: onOpen ?? () {},
      onEnlargePhoto: onEnlargePhoto ?? () {},
    );

void main() {
  testWidgets('shows the topic, the question and when it was asked',
      (tester) async {
    await tester.pumpWidget(_host(SavedQuestionRowMolecule(params: _row())));

    expect(find.text('Geometry · Area'), findsOneWidget);
    expect(find.text('Find the area of the paddock.'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.byKey(const Key('photo_thumbnail_fallback')), findsOneWidget);
  });

  testWidgets('keeps each line to one line', (tester) async {
    await tester.pumpWidget(_host(SavedQuestionRowMolecule(params: _row())));

    expect(tester.widget<Text>(find.text('Geometry · Area')).maxLines, 1);
    expect(
      tester.widget<Text>(find.text('Find the area of the paddock.')).maxLines,
      1,
    );
  });

  testWidgets('shows no second line when there is nothing to show',
      (tester) async {
    await tester
        .pumpWidget(_host(SavedQuestionRowMolecule(params: _row(detail: ''))));

    expect(find.text('Geometry · Area'), findsOneWidget);
    expect(find.byType(Text), findsNWidgets(2),
        reason: 'only the title and when it was asked');
  });

  testWidgets('tapping the row opens the solution', (tester) async {
    var opens = 0;
    var enlarges = 0;
    await tester.pumpWidget(_host(SavedQuestionRowMolecule(
      params: _row(onOpen: () => opens++, onEnlargePhoto: () => enlarges++),
    )));

    await tester.tap(find.text('Geometry · Area'));

    expect(opens, 1);
    expect(enlarges, 0);
  });

  testWidgets('tapping the photo shows the full photo', (tester) async {
    var opens = 0;
    var enlarges = 0;
    await tester.pumpWidget(_host(SavedQuestionRowMolecule(
      params: _row(onOpen: () => opens++, onEnlargePhoto: () => enlarges++),
    )));

    await tester.tap(find.byKey(const Key('saved_question_photo')));

    expect(enlarges, 1);
    expect(opens, 0, reason: 'the photo must not also open the solution');
  });
}
