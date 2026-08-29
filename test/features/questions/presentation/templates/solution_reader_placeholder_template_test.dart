import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/templates/solution_reader_placeholder_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pump(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(home: child),
  );
}

void main() {
  testWidgets('waits with a spinner and no message', (tester) async {
    await tester.pumpWidget(_pump(const SolutionReaderPlaceholderTemplate()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('solution_reader_message')), findsNothing);
  });

  testWidgets('shows the failure instead of the spinner', (tester) async {
    await tester.pumpWidget(_pump(
      const SolutionReaderPlaceholderTemplate(
        message: 'We could not open this solution.',
      ),
    ));
    await tester.pump();

    expect(find.byKey(const Key('solution_reader_message')), findsOneWidget);
    expect(find.text('We could not open this solution.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('owns one Scaffold in the reader colours, never a white flash',
      (tester) async {
    for (final template in const [
      SolutionReaderPlaceholderTemplate(),
      SolutionReaderPlaceholderTemplate(message: 'Something went wrong.'),
    ]) {
      await tester.pumpWidget(_pump(template));
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        QuestPalette.night,
        reason: 'arriving at a solution must not flash a bare white page',
      );
    }
  });
}
