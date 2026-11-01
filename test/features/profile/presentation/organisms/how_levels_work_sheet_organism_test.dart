import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/profile/presentation/organisms/how_levels_work_sheet_organism.dart';
import 'package:doormer/src/shared/design/atomic/atoms/level_icons_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpSheet(
  WidgetTester tester, {
  required VoidCallback onClose,
  double? height,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final sheet = HowLevelsWorkSheetOrganism(onClose: onClose);
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: height == null
            ? sheet
            : Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(height: height, child: sheet),
              ),
      ),
    ),
  ));
}

void main() {
  testWidgets(
      'says what counts, that a level never goes down, and that friends see '
      'it', (tester) async {
    await _pumpSheet(tester, onClose: () {});

    for (final line in [
      'How levels work',
      'Open Doormer on any day and it counts as an active day, once a day.',
      'Your level grows with active days and never goes down, so breaks are '
          'fine.',
      '4 stars make a moon. 4 moons make a sun.',
      'Friends you add see your level.',
    ]) {
      expect(find.text(line), findsOneWidget, reason: line);
    }
  });

  testWidgets('shows 4 stars making a moon, and 4 moons making a sun',
      (tester) async {
    await _pumpSheet(tester, onClose: () {});

    final drawn = [
      for (final icons
          in tester.widgetList<LevelIconsAtom>(find.byType(LevelIconsAtom)))
        (icons.suns, icons.moons, icons.stars),
    ];
    expect(drawn, [(0, 0, 4), (0, 1, 0), (0, 4, 0), (1, 0, 0)]);
  });

  testWidgets('Got it closes it', (tester) async {
    var closes = 0;
    await _pumpSheet(tester, onClose: () => closes++);

    await tester.tap(find.text('Got it'));
    await tester.pump();

    expect(closes, 1);
  });

  testWidgets('in a short space it scrolls, so Got it stays reachable',
      (tester) async {
    var closes = 0;
    await _pumpSheet(tester, height: 240, onClose: () => closes++);

    await tester.ensureVisible(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Got it'));
    await tester.pump();

    expect(closes, 1);
  });
}
