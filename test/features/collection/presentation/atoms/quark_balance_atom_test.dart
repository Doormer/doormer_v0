import 'package:doormer/src/features/collection/presentation/atoms/quark_balance_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  testWidgets('shows the balance beside a quark dot', (tester) async {
    await tester.pumpWidget(_host(const QuarkBalanceAtom(
      quarkBalance: 605,
      dotKey: Key('quark-dot'),
    )));

    expect(find.text('605 quarks'), findsOneWidget);
    expect(find.byKey(const Key('quark-dot')), findsOneWidget);
  });

  testWidgets('a balance of one says quark, not quarks', (tester) async {
    await tester.pumpWidget(_host(const QuarkBalanceAtom(quarkBalance: 1)));

    expect(find.text('1 quark'), findsOneWidget);
  });
}
