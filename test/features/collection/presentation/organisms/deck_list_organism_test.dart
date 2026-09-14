import 'package:doormer/src/features/collection/presentation/molecules/deck_row_molecule.dart';
import 'package:doormer/src/features/collection/presentation/organisms/deck_list_organism.dart';
import 'package:doormer/src/features/collection/presentation/params/deck_row_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 332,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );

DeckRowParams _row(String name) => DeckRowParams(
      deckId: name,
      name: name,
      held: 1,
      total: 6,
      isSelected: false,
      showFlag: true,
      onTap: () {},
    );

void main() {
  testWidgets('renders one row per deck', (tester) async {
    await tester.pumpWidget(_host(DeckListOrganism(
      rows: [_row('Meridian'), _row('Cinder'), _row('Tessera')],
    )));
    expect(find.byType(DeckRowMolecule), findsNWidgets(3));
  });

  testWidgets('does not scroll itself, so the page owns scrolling',
      (tester) async {
    await tester.pumpWidget(_host(DeckListOrganism(
      rows: [_row('Meridian'), _row('Cinder')],
    )));
    // Exactly one scrollable: the host's. A ListView here would make two.
    expect(find.byType(Scrollable), findsOneWidget);
  });
}
