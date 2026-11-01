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
  testWidgets('Find takes the code as the box shows it', (tester) async {
    final finds = await _pump(tester);

    await tester.enterText(find.byType(TextField), 'K7QM 2XPA');
    await tester.tap(find.text('Find'));

    expect(finds, ['K7QM 2XPA']);
  });

  testWidgets('a code typed in lower case shows in capitals', (tester) async {
    final finds = await _pump(tester);

    await tester.enterText(find.byType(TextField), '6u8d 3xma');
    await tester.pump();

    expect(find.text('6U8D 3XMA'), findsOneWidget);
    await tester.tap(find.text('Find'));
    expect(finds, ['6U8D 3XMA']);
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
