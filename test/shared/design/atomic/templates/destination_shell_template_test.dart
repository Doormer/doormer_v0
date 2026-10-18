import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/shared/design/atomic/atoms/cross_fade_indexed_stack_atom.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:doormer/src/shared/design/atomic/templates/destination_shell_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {int shownPageIndex = 1}) async {
  tester.view.physicalSize = const Size(360, 690);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.light,
        home: DestinationShellTemplate(
          navigationBar: NavigationBarParams(
            current: AppDestination.solve,
            onSaved: () {},
            onAiTutor: () {},
            onSolve: () {},
            onCards: () {},
            onProfile: () {},
          ),
          pages: const [Text('Saved page'), Text('Solve page')],
          shownPageIndex: shownPageIndex,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the page at shownPageIndex, keeping the others',
      (tester) async {
    await _pump(tester);

    expect(find.text('Solve page'), findsOneWidget);
    expect(find.text('Saved page'), findsNothing);
    expect(find.text('Saved page', skipOffstage: false), findsOneWidget);
  });

  testWidgets('cross-fades the pages when shownPageIndex changes',
      (tester) async {
    await _pump(tester);
    await _pump(tester, shownPageIndex: 0);
    await tester.pump(CrossFadeIndexedStackAtom.duration ~/ 2);

    expect(find.text('Saved page'), findsOneWidget);
    expect(find.text('Solve page'), findsOneWidget, reason: 'still fading out');

    await tester.pump(CrossFadeIndexedStackAtom.duration);
    expect(find.text('Solve page'), findsNothing);
  });

  testWidgets(
      'the nav bar sits under the pages, clear of the screen edge, '
      'with its params', (tester) async {
    await _pump(tester);

    expect(
      tester.getRect(find.byType(NavigationBar)).bottom,
      moreOrLessEquals(690 - 20.h),
    );
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      AppDestination.solve.index,
    );
  });
}
