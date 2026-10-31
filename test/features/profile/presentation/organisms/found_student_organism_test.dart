import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/profile/presentation/organisms/found_student_organism.dart';
import 'package:doormer/src/features/profile/presentation/params/found_student_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, FoundStudentParams params) =>
    tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: FoundStudentOrganism(params: params)),
      ),
    ));

void main() {
  testWidgets('shows who it is, how the two are connected, and the button',
      (tester) async {
    var taps = 0;
    await _pump(
      tester,
      FoundStudentParams(
        nickname: 'Alex',
        artUrl: null,
        status: "You're friends",
        actionLabel: 'View cards',
        onAction: () => taps++,
        isActing: false,
      ),
    );

    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('A'), findsOneWidget, reason: 'the first letter');
    expect(find.text("You're friends"), findsOneWidget);
    await tester.tap(find.text('View cards'));
    expect(taps, 1);
  });

  testWidgets('with nothing to do, has no button', (tester) async {
    await _pump(
      tester,
      const FoundStudentParams(
        nickname: 'Kai',
        artUrl: null,
        status: "That's your code.",
        actionLabel: null,
        onAction: null,
        isActing: false,
      ),
    );

    expect(find.text("That's your code."), findsOneWidget);
    expect(find.byType(AppButtonAtom), findsNothing);
  });

  testWidgets('the button spins while its action is on its way',
      (tester) async {
    await _pump(
      tester,
      FoundStudentParams(
        nickname: 'Nia',
        artUrl: null,
        status: null,
        actionLabel: 'Send request',
        onAction: () {},
        isActing: true,
      ),
    );

    expect(tester.widget<AppButtonAtom>(find.byType(AppButtonAtom)).isLoading,
        isTrue);
  });
}
