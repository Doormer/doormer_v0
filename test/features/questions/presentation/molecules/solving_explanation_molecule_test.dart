import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/molecules/solving_explanation_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {VoidCallback? onWhyAds}) {
  return tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: SolvingExplanationMolecule(onWhyAds: onWhyAds)),
      ),
    ),
  );
}

void main() {
  testWidgets('tapping "Why ads?" asks for the explanation', (tester) async {
    var whyAdsCount = 0;
    await _pump(tester, onWhyAds: () => whyAdsCount++);

    await tester.tap(find.text('Why ads?'));
    await tester.pump();

    expect(whyAdsCount, 1);
  });

  testWidgets('with ads off, there is no "Why ads?" link', (tester) async {
    await _pump(tester);

    expect(find.text("What's happening"), findsOneWidget);
    expect(find.text('Why ads?'), findsNothing);
  });
}
