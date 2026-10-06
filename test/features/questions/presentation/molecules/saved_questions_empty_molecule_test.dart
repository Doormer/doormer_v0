import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/molecules/saved_questions_empty_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('says nothing is saved yet, and Solve a question calls back',
      (tester) async {
    var solves = 0;
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SavedQuestionsEmptyMolecule(onSolve: () => solves++),
        ),
      ),
    ));

    expect(
      find.text(
          "No solved questions yet. Snap a photo and it'll be saved here."),
      findsOneWidget,
    );
    await tester.tap(find.text('Solve a question'));
    expect(solves, 1);
  });
}
