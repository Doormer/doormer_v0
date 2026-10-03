import 'dart:convert';

import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/molecules/photo_preview_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

final _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

Future<void> _pump(WidgetTester tester, PhotoPreviewMolecule molecule) {
  return tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: molecule),
      ),
    ),
  );
}

void main() {
  testWidgets('with no photo, says which formats work', (tester) async {
    await _pump(tester, const PhotoPreviewMolecule());

    expect(find.text('JPG, PNG or HEIC'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('while preparing, shows progress instead of the hint',
      (tester) async {
    await _pump(tester, const PhotoPreviewMolecule(isPreparing: true));

    expect(find.text('Preparing your photo…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('JPG, PNG or HEIC'), findsNothing);
  });

  testWidgets('while preparing, hides the earlier photo', (tester) async {
    await _pump(
      tester,
      PhotoPreviewMolecule(imageBytes: _pngBytes, isPreparing: true),
    );

    expect(find.text('Preparing your photo…'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
