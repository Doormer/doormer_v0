import 'package:doormer/src/features/collection/presentation/molecules/deck_row_molecule.dart';
import 'package:doormer/src/features/collection/presentation/params/deck_row_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) =>
          MaterialApp(home: Scaffold(body: SizedBox(width: 332, child: child))),
    );

DeckRowParams _params({
  int held = 4,
  int total = 6,
  bool showFlag = true,
  VoidCallback? onTap,
}) =>
    DeckRowParams(
      deckId: 'meridian',
      name: 'Meridian',
      held: held,
      total: total,
      isSelected: false,
      showFlag: showFlag,
      onTap: onTap ?? () {},
    );

void main() {
  testWidgets('shows the name and the count as digits', (tester) async {
    await tester.pumpWidget(_host(DeckRowMolecule(params: _params())));
    expect(find.text('Meridian'), findsOneWidget);
    expect(find.text('4/6'), findsOneWidget);
  });

  testWidgets('a finished deck flags Complete', (tester) async {
    // The default 800x600 test viewport is wider than the 360 design canvas,
    // so ScreenUtil overscales every dimension and the row overflows before
    // this assertion ever sees the real layout. Match the design canvas so
    // the test measures the widget, not the harness.
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(DeckRowMolecule(params: _params(held: 6))));
    expect(find.text('Complete'), findsOneWidget);
  });

  testWidgets('an untouched deck flags New', (tester) async {
    await tester.pumpWidget(_host(DeckRowMolecule(params: _params(held: 0))));
    expect(find.text('New'), findsOneWidget);
  });

  testWidgets('a part-filled deck flags nothing', (tester) async {
    await tester.pumpWidget(_host(DeckRowMolecule(params: _params(held: 3))));
    expect(find.text('New'), findsNothing);
    expect(find.text('Complete'), findsNothing);
  });

  testWidgets('the narrow rail drops the flag but keeps the count',
      (tester) async {
    await tester.pumpWidget(_host(
      DeckRowMolecule(params: _params(held: 6, showFlag: false)),
    ));
    expect(find.text('Complete'), findsNothing);
    expect(find.text('6/6'), findsOneWidget);
  });

  testWidgets('tapping reports the deck', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(
      DeckRowMolecule(params: _params(onTap: () => taps++)),
    ));
    await tester.tap(find.byType(DeckRowMolecule));
    expect(taps, 1);
  });
}
