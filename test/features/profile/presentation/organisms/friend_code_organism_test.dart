import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/profile/presentation/organisms/friend_code_organism.dart';
import 'package:doormer/src/features/profile/presentation/params/friend_code_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<String>> _pump(WidgetTester tester,
    {bool isResetting = false}) async {
  final taps = <String>[];
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: FriendCodeOrganism(
          params: FriendCodeParams(
            friendCode: 'K7QM-2XPA',
            isResetting: isResetting,
            onCopyCode: () => taps.add('copy code'),
            onCopyInviteLink: () => taps.add('copy link'),
            onResetCode: () => taps.add('reset'),
          ),
        ),
      ),
    ),
  ));
  return taps;
}

void main() {
  testWidgets('shows the code, with Copy, Copy invite link and Reset code',
      (tester) async {
    final taps = await _pump(tester);

    expect(find.text('K7QM-2XPA'), findsOneWidget);
    await tester.tap(find.text('Copy'));
    await tester.tap(find.text('Copy invite link'));
    await tester.tap(find.text('Reset code'));

    expect(taps, ['copy code', 'copy link', 'reset']);
  });

  testWidgets('while a new code is on its way, nothing can be tapped',
      (tester) async {
    final taps = await _pump(tester, isResetting: true);

    await tester.tap(find.text('Copy'));
    await tester.tap(find.text('Reset code'));

    expect(taps, isEmpty);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
