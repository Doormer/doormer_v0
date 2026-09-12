import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/templates/solution_reader_placeholder_template.dart';
import 'package:doormer/src/shared/design/atomic/atoms/quest_backdrop.dart';
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

  testWidgets('owns one Scaffold and paints no colour of its own',
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
        isNull,
        reason: 'the shell backdrop shows through, so the page adds no fill',
      );
    }
  });

  testWidgets('mounted the way the app mounts it, never flashes a white page',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const ResponsiveAppShell(
          child: SolutionReaderPlaceholderTemplate(),
        ),
      ),
    );
    await tester.pump();

    // The dark page is the shell's job now, not each template's. Prove the
    // backdrop really is painted behind the placeholder, across the whole
    // window -- a transparent Scaffold over nothing would be a white flash.
    final backdrop = find.byType(QuestBackdrop);
    expect(backdrop, findsOneWidget);
    expect(tester.getSize(backdrop), const Size(1440, 900));

    expect(
      find.descendant(
        of: backdrop,
        matching: find.byType(SolutionReaderPlaceholderTemplate),
      ),
      findsOneWidget,
      reason: 'the placeholder must sit inside the backdrop, not beside it',
    );
  });
}
