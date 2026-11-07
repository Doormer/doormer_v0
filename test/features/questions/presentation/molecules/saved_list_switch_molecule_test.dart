import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/molecules/saved_list_switch_molecule.dart';
import 'package:doormer/src/features/questions/presentation/params/saved_list_switch_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<SavedList>> _pump(
  WidgetTester tester, {
  SavedList selected = SavedList.mine,
  double width = 360,
}) async {
  tester.view.physicalSize = Size(width, 690);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final chosen = <SavedList>[];
  await tester.pumpWidget(ScreenUtilInit(
    designSize: Size(width, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SavedListSwitchMolecule(
            params: SavedListSwitchParams(
              selected: selected,
              onSelect: chosen.add,
            ),
          ),
        ),
      ),
    ),
  ));
  return chosen;
}

void main() {
  testWidgets('offers Mine and Shared with me, with the one shown selected',
      (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    expect(tester.getSemantics(find.text('Mine')),
        containsSemantics(isButton: true, isSelected: true));
    expect(tester.getSemantics(find.text('Shared with me')),
        containsSemantics(isButton: true, isSelected: false));

    await _pump(tester, selected: SavedList.sharedWithMe);
    expect(tester.getSemantics(find.text('Mine')),
        containsSemantics(isSelected: false));
    expect(tester.getSemantics(find.text('Shared with me')),
        containsSemantics(isSelected: true));
    handle.dispose();
  });

  testWidgets('tapping a list asks for it', (tester) async {
    final chosen = await _pump(tester);

    await tester.tap(find.text('Shared with me'));
    await tester.tap(find.text('Mine'));

    expect(chosen, [SavedList.sharedWithMe, SavedList.mine]);
  });

  testWidgets('keeps its own width on a wide screen', (tester) async {
    await _pump(tester, width: 760);

    final shared = tester.getRect(find.text('Shared with me'));
    expect(shared.right, lessThan(380));
  });
}
