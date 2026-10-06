import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/molecules/study_tip_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the tip under its heading', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: StudyTipMolecule(tip: 'Check your answer.'),
          ),
        ),
      ),
    );

    expect(find.text('Tip'), findsOneWidget);
    expect(find.text('Check your answer.'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Tip')).dy,
      lessThan(tester.getTopLeft(find.text('Check your answer.')).dy),
    );
  });
}
