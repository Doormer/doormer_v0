import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/profile/presentation/organisms/picture_picker_organism.dart';
import 'package:doormer/src/features/profile/presentation/params/picture_picker_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<String>> _pump(
  WidgetTester tester, {
  List<String> cards = const ['Gnomon', 'Vernier'],
  String? chosen,
}) async {
  final taps = <String>[];
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: PicturePickerOrganism(
          params: PicturePickerParams(
            nickname: 'Rangi',
            isFirstLetterChosen: chosen == null,
            onChooseFirstLetter: () => taps.add('first letter'),
            cards: [
              for (final card in cards)
                PictureOptionParams(
                  name: card,
                  artUrl: '',
                  isChosen: card == chosen,
                  onChoose: () => taps.add(card),
                ),
            ],
          ),
        ),
      ),
    ),
  ));
  return taps;
}

void main() {
  testWidgets('offers the first letter, then each card', (tester) async {
    final semantics = tester.ensureSemantics();
    final taps = await _pump(tester);

    expect(find.text('R'), findsOneWidget, reason: "Rangi's first letter");
    await tester.tap(find.bySemanticsLabel('Vernier'));
    await tester.tap(find.bySemanticsLabel('First letter'));

    expect(taps, ['Vernier', 'first letter']);
    semantics.dispose();
  });

  testWidgets('marks the one picked as a checked radio button', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, chosen: 'Gnomon');

    // The web reads `checked`, as aria-checked, but not `selected`.
    expect(
      tester.getSemantics(find.bySemanticsLabel('Gnomon')),
      containsSemantics(
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('First letter')),
      containsSemantics(
        hasCheckedState: true,
        isChecked: false,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('with no cards yet, says the letter shows until there is one',
      (tester) async {
    await _pump(tester, cards: const []);

    expect(
      find.text('Your first letter shows until you have a card. '
          'Draw one on Cards.'),
      findsOneWidget,
    );
  });

  testWidgets('with cards, says nothing about drawing one', (tester) async {
    await _pump(tester);

    expect(find.textContaining('Draw one on Cards'), findsNothing);
  });
}
