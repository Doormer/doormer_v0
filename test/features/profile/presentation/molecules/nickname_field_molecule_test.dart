import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/profile/presentation/molecules/nickname_field_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<String>> _pump(WidgetTester tester, {String? problem}) async {
  final changes = <String>[];
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: NicknameFieldMolecule(
        initialNickname: 'Kai',
        problem: problem,
        onChanged: changes.add,
        onSubmitted: () => changes.add('submitted'),
      ),
    ),
  ));
  return changes;
}

void main() {
  testWidgets('starts from the saved nickname, with the hint', (tester) async {
    await _pump(tester);

    expect(find.text('Kai'), findsOneWidget);
    expect(find.text('Nickname'), findsOneWidget);
    expect(find.text("Don't use your full name."), findsOneWidget);
  });

  testWidgets('says what to change in place of the hint', (tester) async {
    await _pump(tester, problem: 'Include at least one letter.');

    expect(find.text('Include at least one letter.'), findsOneWidget);
    expect(find.text("Don't use your full name."), findsNothing);
  });

  testWidgets('reports what is typed, and Enter', (tester) async {
    final changes = await _pump(tester);

    await tester.enterText(find.byType(TextFormField), 'Kaia');
    await tester.testTextInput.receiveAction(TextInputAction.done);

    expect(changes, ['Kaia', 'submitted']);
  });
}
