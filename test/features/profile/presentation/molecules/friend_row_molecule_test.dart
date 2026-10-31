import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/profile/presentation/molecules/friend_row_molecule.dart';
import 'package:doormer/src/features/profile/presentation/params/friend_row_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<String>> _pump(WidgetTester tester, {bool isBusy = false}) async {
  final taps = <String>[];
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: FriendRowMolecule(
          params: FriendRowParams(
            nickname: 'Sam',
            artUrl: null,
            isBusy: isBusy,
            onOpen: () => taps.add('open'),
            onRemove: () => taps.add('remove'),
            onBlock: () => taps.add('block'),
            onReport: () => taps.add('report'),
          ),
        ),
      ),
    ),
  ));
  return taps;
}

void main() {
  testWidgets("shows the friend's picture and nickname", (tester) async {
    await _pump(tester);

    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('S'), findsOneWidget, reason: 'the first letter');
  });

  testWidgets('opens the friend', (tester) async {
    final taps = await _pump(tester);

    await tester.tap(find.text('Sam'));

    expect(taps, ['open']);
  });

  for (final action in ['Remove', 'Block', 'Report']) {
    testWidgets('the menu has $action', (tester) async {
      final taps = await _pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();

      expect(taps, [action.toLowerCase()]);
    });
  }

  testWidgets('while a change is on its way, waits and does nothing',
      (tester) async {
    final taps = await _pump(tester, isBusy: true);

    await tester.tap(find.text('Sam'));

    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(taps, isEmpty);
  });
}
