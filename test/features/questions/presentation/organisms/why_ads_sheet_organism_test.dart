import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/organisms/why_ads_sheet_organism.dart';
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
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final sheet = WhyAdsSheetOrganism(onClose: onClose);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: height == null
              ? sheet
              : Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(height: height, child: sheet),
                ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('"Got it" closes the explanation', (tester) async {
    var closeCount = 0;
    await _pumpSheet(tester, onClose: () => closeCount++);

    await tester.tap(find.text('Got it'));
    await tester.pump();

    expect(closeCount, 1);
  });

  testWidgets(
      'in a short space the explanation scrolls, so "Got it" stays '
      'reachable', (tester) async {
    var closeCount = 0;
    await _pumpSheet(tester, height: 240, onClose: () => closeCount++);

    await tester.ensureVisible(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Got it'));
    await tester.pump();

    expect(closeCount, 1);
  });
}
