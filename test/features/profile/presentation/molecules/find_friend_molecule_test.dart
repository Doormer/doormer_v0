import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/profile/presentation/molecules/find_friend_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<String>> _pump(WidgetTester tester,
    {String initialCode = ''}) async {
  final finds = <String>[];
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: FindFriendMolecule(
          initialCode: initialCode,
          isFinding: false,
          onFind: finds.add,
        ),
      ),
    ),
  ));
  return finds;
}

void main() {
  testWidgets('Find takes the code as typed', (tester) async {
    final finds = await _pump(tester);

    await tester.enterText(find.byType(TextField), 'k7qm 2xpa');
    await tester.tap(find.text('Find'));

    expect(finds, ['k7qm 2xpa']);
  });

  testWidgets('Enter finds too', (tester) async {
    final finds = await _pump(tester);

    await tester.enterText(find.byType(TextField), 'K7QM2XPA');
    await tester.testTextInput.receiveAction(TextInputAction.search);

    expect(finds, ['K7QM2XPA']);
  });

  testWidgets("starts with an invite's code", (tester) async {
    await _pump(tester, initialCode: 'RUAR-5555');

    expect(find.text('RUAR-5555'), findsOneWidget);
  });
}
