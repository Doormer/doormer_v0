import 'package:doormer/src/core/theme/quest_palette.dart';
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

TextStyle _labelStyle(WidgetTester tester) =>
    tester.widget<Text>(find.text('605 quarks')).style!;

BoxDecoration _dot(WidgetTester tester) =>
    tester.widget<Container>(find.byKey(const Key('quark-dot'))).decoration!
        as BoxDecoration;

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

  testWidgets('a balance that does not glow is dim, with no shadows',
      (tester) async {
    await tester.pumpWidget(_host(const QuarkBalanceAtom(
      quarkBalance: 605,
      dotKey: Key('quark-dot'),
    )));

    expect(_labelStyle(tester).color, QuestPalette.dim);
    expect(_labelStyle(tester).shadows ?? const <Shadow>[], isEmpty);
    expect(_dot(tester).boxShadow ?? const <BoxShadow>[], isEmpty);
  });

  testWidgets(
      'a glowing balance turns amber and glows, without changing its size, so '
      'quark dots aimed at it still land on it', (tester) async {
    await tester.pumpWidget(_host(const QuarkBalanceAtom(
      quarkBalance: 605,
      dotKey: Key('quark-dot'),
    )));
    final size = tester.getSize(find.byType(QuarkBalanceAtom));

    await tester.pumpWidget(_host(const QuarkBalanceAtom(
      quarkBalance: 605,
      dotKey: Key('quark-dot'),
      glow: 1,
    )));

    expect(_labelStyle(tester).color, QuestPalette.amber);
    expect(_labelStyle(tester).shadows, isNotEmpty);
    expect(_dot(tester).boxShadow, isNotEmpty);
    expect(tester.getSize(find.byType(QuarkBalanceAtom)), size);
  });
}
