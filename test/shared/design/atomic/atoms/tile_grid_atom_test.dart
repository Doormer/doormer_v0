import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/shared/design/atomic/atoms/tile_grid_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// [grid] in a space 300 wide.
Future<void> _pump(WidgetTester tester, TileGridAtom grid) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 690);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 300, child: grid),
        ),
      ),
    ),
  ));
}

/// Where the tile saying [text] is laid out.
Rect _tile(WidgetTester tester, String text) => tester.getRect(find.text(text));

void main() {
  testWidgets('lays tiles out two to a line, each as wide as the others',
      (tester) async {
    await _pump(
      tester,
      const TileGridAtom(
        columns: 2,
        children: [Text('Alex'), Text('Sam'), Text('Tama')],
      ),
    );

    final alex = _tile(tester, 'Alex');
    final sam = _tile(tester, 'Sam');
    final tama = _tile(tester, 'Tama');
    expect(sam.top, alex.top);
    expect(sam.left - alex.right, 12);
    expect(alex.left, 0);
    expect(sam.right, moreOrLessEquals(300));
    expect(sam.width, moreOrLessEquals(alex.width));
    expect(tama.top - alex.bottom, 12, reason: 'the next line');
    expect(tama.left, alex.left);
    expect(tama.width, moreOrLessEquals(alex.width),
        reason: 'a tile alone on its line keeps the same width');
  });

  testWidgets("a line's tiles are as tall as its tallest", (tester) async {
    await _pump(
      tester,
      const TileGridAtom(
        columns: 2,
        children: [Text('Alex'), Text('Sam\nand more')],
      ),
    );

    expect(_tile(tester, 'Alex').height, _tile(tester, 'Sam\nand more').height);
  });
}
