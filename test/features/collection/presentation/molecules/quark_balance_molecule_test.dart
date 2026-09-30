import 'package:doormer/src/features/collection/presentation/atoms/quark_balance_atom.dart';
import 'package:doormer/src/features/collection/presentation/molecules/quark_balance_molecule.dart';
import 'package:doormer/src/shared/design/atomic/atoms/punch_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(int quarkBalance, {bool motion = true, Key? dotKey}) =>
    ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: !motion),
            child: Scaffold(
              body: Center(
                child: QuarkBalanceMolecule(
                  quarkBalance: quarkBalance,
                  dotKey: dotKey,
                ),
              ),
            ),
          ),
        ),
      ),
    );

/// Rebuilds the balance with [quarkBalance], as a shatter's answer does.
///
/// The second frame starts the clock, as it does for the shatter, so a
/// `pump(const Duration(milliseconds: 800))` after this lands at 0.8.
Future<void> _rise(WidgetTester tester, int quarkBalance) async {
  await tester.pumpWidget(_host(quarkBalance));
  await tester.pump();
}

bool _punching(WidgetTester tester) => find
    .descendant(of: find.byType(PunchAtom), matching: find.byType(Transform))
    .evaluate()
    .isNotEmpty;

void main() {
  testWidgets('shows the balance, and the first build is not a rise',
      (tester) async {
    await tester.pumpWidget(_host(600));
    await tester.pump();

    expect(find.text('600 quarks'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('puts dotKey on the quark dot, so a shatter can aim at it',
      (tester) async {
    final dotKey = GlobalKey();
    await tester.pumpWidget(_host(600, dotKey: dotKey));

    expect(
      find.descendant(
          of: find.byType(QuarkBalanceAtom), matching: find.byKey(dotKey)),
      findsOneWidget,
    );
  });

  testWidgets(
      'a rise holds until the quark dots land, counts up while they land, '
      'and punches once as the last one lands', (tester) async {
    await tester.pumpWidget(_host(600));
    await _rise(tester, 611);
    expect(find.text('600 quarks'), findsOneWidget,
        reason: 'the quarks are still on their way');

    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('600 quarks'), findsOneWidget,
        reason: 'at 0.7 no quark dot has landed');

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('604 quarks'), findsOneWidget,
        reason: 'at 0.8 a third of the landing is done: 11 ÷ 3, rounded up');
    expect(_punching(tester), isFalse, reason: 'no punch while counting');

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('611 quarks'), findsOneWidget,
        reason: 'at 0.9 the last quark dot lands');
    await tester.pump(const Duration(milliseconds: 50));
    expect(_punching(tester), isTrue);

    await tester.pumpAndSettle();
    expect(find.text('611 quarks'), findsOneWidget);
    expect(_punching(tester), isFalse);
  });

  testWidgets('a fall shows at once, without a punch', (tester) async {
    await tester.pumpWidget(_host(600));
    await tester.pumpWidget(_host(560));

    expect(find.text('560 quarks'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 50));
    expect(_punching(tester), isFalse,
        reason: 'only quarks arriving are an event');
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('with motion off, a rise shows at once', (tester) async {
    await tester.pumpWidget(_host(600, motion: false));
    await tester.pumpWidget(_host(611, motion: false));

    expect(find.text('611 quarks'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('the next rise jumps a running count to its end', (tester) async {
    await tester.pumpWidget(_host(600));
    await _rise(tester, 611);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('600 quarks'), findsOneWidget);

    await tester.pumpWidget(_host(622));
    expect(find.text('611 quarks'), findsOneWidget,
        reason: 'the first rise keeps its quarks, and the next counts up '
            'from there');

    await tester.pumpAndSettle();
    expect(find.text('622 quarks'), findsOneWidget);
  });
}
