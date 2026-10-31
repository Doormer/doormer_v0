import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/profile/presentation/molecules/friend_request_row_molecule.dart';
import 'package:doormer/src/features/profile/presentation/params/friend_request_row_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
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
        body: FriendRequestRowMolecule(
          params: FriendRequestRowParams(
            nickname: 'Rua',
            artUrl: null,
            isBusy: isBusy,
            onAccept: () => taps.add('accept'),
            onDecline: () => taps.add('decline'),
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
  testWidgets('Accept and Decline answer the request', (tester) async {
    final taps = await _pump(tester);

    expect(find.text('Rua'), findsOneWidget);
    await tester.tap(find.text('Accept'));
    await tester.tap(find.text('Decline'));

    expect(taps, ['accept', 'decline']);
  });

  for (final action in ['Block', 'Report']) {
    testWidgets('the menu has $action', (tester) async {
      final taps = await _pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();

      expect(taps, [action.toLowerCase()]);
    });
  }

  testWidgets('while an answer is on its way, nothing can be tapped',
      (tester) async {
    await _pump(tester, isBusy: true);

    for (final button in tester.widgetList<AppButtonAtom>(
      find.byType(AppButtonAtom),
    )) {
      expect(button.onPressed, isNull, reason: button.label);
    }
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });
}
