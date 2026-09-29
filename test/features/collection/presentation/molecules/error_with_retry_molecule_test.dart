import 'package:doormer/src/features/collection/presentation/molecules/error_with_retry_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('says why, and Retry calls back', (tester) async {
    var retries = 0;
    await tester.pumpWidget(_host(ErrorWithRetryMolecule(
      message: "We couldn't connect. Check your connection and try again.",
      onRetry: () => retries++,
    )));

    expect(
      find.text("We couldn't connect. Check your connection and try again."),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });
}
