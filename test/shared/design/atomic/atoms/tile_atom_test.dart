import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/shared/design/atomic/atoms/tile_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// [tile] in a space 300 wide.
Future<void> _pump(WidgetTester tester, TileAtom tile) async {
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
          child: SizedBox(width: 300, child: tile),
        ),
      ),
    ),
  ));
}

void main() {
  testWidgets('with onTap, the whole tile is one tap target, its rim included',
      (tester) async {
    var taps = 0;
    await _pump(
        tester, TileAtom(onTap: () => taps++, child: const Text('Sam')));

    final tile = tester.getRect(find.byType(TileAtom));
    await tester.tapAt(Offset(tile.left + 4, tile.center.dy));
    await tester.tapAt(Offset(tile.center.dx, tile.top + 4));
    await tester.tap(find.text('Sam'));

    expect(taps, 3);
  });

  testWidgets('a button on the tile takes its own taps', (tester) async {
    final taps = <String>[];
    await _pump(
      tester,
      TileAtom(
        onTap: () => taps.add('tile'),
        child: Row(
          children: [
            const Expanded(child: Text('Sam')),
            IconButton(
              onPressed: () => taps.add('menu'),
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert));

    expect(taps, ['menu']);
  });
}
