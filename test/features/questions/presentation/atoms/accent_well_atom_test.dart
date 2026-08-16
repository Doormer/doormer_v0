import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/atoms/accent_well_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pump(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: Center(child: SizedBox(width: 320, child: child))),
    ),
  );
}

void main() {
  testWidgets('paints without throwing on the rounded rail', (tester) async {
    await tester.pumpWidget(_pump(
      const AccentWellAtom(
        accent: QuestPalette.pink,
        child: Text('an equation'),
      ),
    ));
    await tester.pump();

    // The regression: expressing the rail as `Border(left: ...)` alongside a
    // `borderRadius` compiles and analyzes clean, then throws "A borderRadius
    // can only be given on borders with uniform colors" the first time it
    // paints. Nothing but rendering it catches that, so this test renders it.
    expect(tester.takeException(), isNull);
    expect(find.text('an equation'), findsOneWidget);
  });

  testWidgets('draws the rail in the accent colour', (tester) async {
    await tester.pumpWidget(_pump(
      const AccentWellAtom(
        accent: QuestPalette.amber,
        child: Text('a caveat'),
      ),
    ));
    await tester.pump();

    final rails = tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .where((box) => box.color == QuestPalette.amber);

    expect(rails, hasLength(1));
  });
}
