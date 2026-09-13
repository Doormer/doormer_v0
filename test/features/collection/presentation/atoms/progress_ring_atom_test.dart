import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/collection/presentation/atoms/progress_ring_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(home: Scaffold(body: Center(child: child))),
    );

void main() {
  testWidgets('shows the held count as digits', (tester) async {
    await tester.pumpWidget(_host(const ProgressRingAtom(held: 147, total: 200)));
    expect(find.text('147'), findsOneWidget);
  });

  testWidgets('a complete deck rings mint, matching a completed card', (tester) async {
    await tester.pumpWidget(_host(const ProgressRingAtom(held: 6, total: 6)));
    final atom = tester.widget<ProgressRingAtom>(find.byType(ProgressRingAtom));
    expect(atom.isComplete, isTrue);
    expect(atom.ringColour, QuestPalette.mint);
  });

  testWidgets('an untouched deck is not complete and does not ring mint', (tester) async {
    await tester.pumpWidget(_host(const ProgressRingAtom(held: 0, total: 9)));
    final atom = tester.widget<ProgressRingAtom>(find.byType(ProgressRingAtom));
    expect(atom.isComplete, isFalse);
    expect(atom.ringColour, isNot(QuestPalette.mint));
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('an empty deck does not divide by zero', (tester) async {
    await tester.pumpWidget(_host(const ProgressRingAtom(held: 0, total: 0)));
    final atom = tester.widget<ProgressRingAtom>(find.byType(ProgressRingAtom));
    expect(atom.fraction, 0.0);
    expect(atom.isComplete, isFalse);
  });
}
