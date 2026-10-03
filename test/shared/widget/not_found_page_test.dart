import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/shared/widget/not_found_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('says the page is missing and offers a way home', (tester) async {
    var wentHome = 0;
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.light,
        home: NotFoundPage(onGoHome: () => wentHome++),
      ),
    ));

    expect(find.text('Page not found'), findsOneWidget);
    await tester.tap(find.text('Go home'));
    expect(wentHome, 1);
  });
}
