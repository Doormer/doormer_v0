import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/molecules/questions_left_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _noneLeft = "You've used today's questions. They reset at midnight.";

Future<void> _pump(
  WidgetTester tester, {
  required String text,
  required bool isReached,
}) {
  return tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: QuestionsLeftMolecule(text: text, isReached: isReached),
        ),
      ),
    ),
  );
}

FontWeight? _weightOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.fontWeight;

void main() {
  testWidgets('shows the questions left today', (tester) async {
    await _pump(tester, text: '3 questions left today', isReached: false);

    expect(find.text('3 questions left today'), findsOneWidget);
  });

  testWidgets('with none left, the line is bolder than the count',
      (tester) async {
    await _pump(tester, text: '3 questions left today', isReached: false);
    expect(_weightOf(tester, '3 questions left today'), FontWeight.w500);

    await _pump(tester, text: _noneLeft, isReached: true);
    expect(_weightOf(tester, _noneLeft), FontWeight.w700);
  });

  testWidgets('the line is announced when it changes', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, text: '3 questions left today', isReached: false);

    expect(
      tester.getSemantics(find.text('3 questions left today')),
      matchesSemantics(label: '3 questions left today', isLiveRegion: true),
    );
    handle.dispose();
  });
}
