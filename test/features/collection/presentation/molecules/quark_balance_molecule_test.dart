import 'package:doormer/src/features/collection/presentation/atoms/quark_balance_atom.dart';
import 'package:doormer/src/features/collection/presentation/molecules/quark_balance_molecule.dart';
import 'package:doormer/src/shared/design/atomic/atoms/punch_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(
  int quarkBalance, {
  bool motion = true,
  Key? dotKey,
  bool showBalance = true,
}) =>
    ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: !motion),
            child: Scaffold(
              body: Center(
                child: showBalance
                    ? QuarkBalanceMolecule(
                        quarkBalance: quarkBalance,
                        dotKey: dotKey,
                      )
                    : const SizedBox(),
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

/// The number the balance shows. While the balance is lifted it is drawn
/// twice, and both copies must show the same number.
int _shown(WidgetTester tester) {
  final shown = tester
      .widgetList<QuarkBalanceAtom>(find.byType(QuarkBalanceAtom))
      .map((balance) => balance.quarkBalance)
      .toSet();
  expect(shown, hasLength(1), reason: 'both copies show the same number');
  return shown.single;
}

final _lifted = find.byKey(const Key('quark-balance-lifted'));

final _inPlace = find.descendant(
  of: find.byType(QuarkBalanceMolecule),
  matching: find.byType(QuarkBalanceAtom),
);

final _liftedBalance =
    find.descendant(of: _lifted, matching: find.byType(QuarkBalanceAtom));

double _inPlaceOpacity(WidgetTester tester) => tester
    .widget<Opacity>(find.descendant(
        of: find.byType(QuarkBalanceMolecule), matching: find.byType(Opacity)))
    .opacity;

double _liftedGlow(WidgetTester tester) =>
    tester.widget<QuarkBalanceAtom>(_liftedBalance).glow;

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
    expect(_shown(tester), 600, reason: 'the quarks are still on their way');

    await tester.pump(const Duration(milliseconds: 700));
    expect(_shown(tester), 600, reason: 'at 0.7 no quark dot has landed');

    await tester.pump(const Duration(milliseconds: 100));
    expect(_shown(tester), 604,
        reason: 'at 0.8 a third of the landing is done: 11 ÷ 3, rounded up');
    expect(_punching(tester), isFalse, reason: 'no punch while counting');

    await tester.pump(const Duration(milliseconds: 100));
    expect(_shown(tester), 611, reason: 'at 0.9 the last quark dot lands');
    await tester.pump(const Duration(milliseconds: 50));
    expect(_punching(tester), isTrue);

    await tester.pumpAndSettle();
    expect(_shown(tester), 611);
    expect(_punching(tester), isFalse);
  });

  testWidgets('a fall shows at once, without a punch or a glow',
      (tester) async {
    await tester.pumpWidget(_host(600));
    await tester.pumpWidget(_host(560));

    expect(find.text('560 quarks'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 850));
    expect(_punching(tester), isFalse,
        reason: 'only quarks arriving are an event');
    expect(_lifted, findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('with motion off, a rise shows at once, without a glow',
      (tester) async {
    await tester.pumpWidget(_host(600, motion: false));
    await tester.pumpWidget(_host(611, motion: false));

    expect(find.text('611 quarks'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 850));
    expect(_lifted, findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('the next rise jumps a running count to its end', (tester) async {
    await tester.pumpWidget(_host(600));
    await _rise(tester, 611);
    await tester.pump(const Duration(milliseconds: 500));
    expect(_shown(tester), 600);

    await tester.pumpWidget(_host(622));
    expect(_shown(tester), 611,
        reason: 'the first rise keeps its quarks, and the next counts up '
            'from there');

    await tester.pumpAndSettle();
    expect(_shown(tester), 622);
  });

  testWidgets(
      'as the quark dots land, the balance lifts above the page and lights '
      'up, then settles back', (tester) async {
    await tester.pumpWidget(_host(600));
    await _rise(tester, 611);

    await tester.pump(const Duration(milliseconds: 700));
    expect(_lifted, findsNothing, reason: 'no quark dot has landed yet');

    await tester.pump(const Duration(milliseconds: 150));
    expect(_lifted, findsOneWidget, reason: 'at 0.85 the dots are landing');
    expect(find.ancestor(of: _lifted, matching: find.byType(Scaffold)),
        findsNothing,
        reason: "it is drawn in the app's overlay, above the page and any "
            'card window');
    expect(_liftedGlow(tester), 1);
    expect(_inPlaceOpacity(tester), 0);
    expect(tester.getTopLeft(_liftedBalance),
        offsetMoreOrLessEquals(tester.getTopLeft(_inPlace)),
        reason: 'it covers the balance in place exactly');
    expect(tester.getSize(_liftedBalance), tester.getSize(_inPlace));
    expect(_shown(tester), greaterThan(600));

    await tester.pump(const Duration(milliseconds: 250));
    expect(_liftedGlow(tester), 1, reason: 'at 1.1 it is still lit');

    await tester.pumpAndSettle();
    expect(_lifted, findsNothing);
    expect(_inPlaceOpacity(tester), 1);
    expect(_shown(tester), 611);
  });

  testWidgets('a fall drops a lit balance back at once', (tester) async {
    await tester.pumpWidget(_host(600));
    await _rise(tester, 611);
    await tester.pump(const Duration(milliseconds: 850));
    expect(_lifted, findsOneWidget);

    await tester.pumpWidget(_host(571));
    await tester.pump(); // The overlay lets go of the lifted copy a frame on.

    expect(_lifted, findsNothing);
    expect(_inPlaceOpacity(tester), 1);
    expect(_shown(tester), 571);
  });

  testWidgets(
      'a rise that arrives while the balance is lit keeps it lit until its '
      'own quark dots land', (tester) async {
    await tester.pumpWidget(_host(600));
    await _rise(tester, 611);
    await tester.pump(const Duration(milliseconds: 1300));
    final settling = _liftedGlow(tester);
    expect(settling, inExclusiveRange(0, 1), reason: 'at 1.3 it is settling');

    await _rise(tester, 622);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_liftedGlow(tester), settling,
        reason: 'it holds its glow while the new quark dots fly, rather than '
            'going dim and lighting up again');

    await tester.pump(const Duration(milliseconds: 550));
    expect(_liftedGlow(tester), 1);

    await tester.pumpAndSettle();
    expect(_lifted, findsNothing);
    expect(_shown(tester), 622);
  });

  testWidgets('a lit balance that leaves takes its lifted copy with it',
      (tester) async {
    await tester.pumpWidget(_host(600));
    await _rise(tester, 611);
    await tester.pump(const Duration(milliseconds: 850));
    expect(_lifted, findsOneWidget);

    await tester.pumpWidget(_host(611, showBalance: false));
    await tester.pump(); // The overlay lets go of the lifted copy a frame on.

    expect(_lifted, findsNothing);
  });
}
