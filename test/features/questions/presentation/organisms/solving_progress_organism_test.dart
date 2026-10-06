import 'dart:convert';

import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/atoms/elapsed_time_atom.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solving_progress_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/solving_progress_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

// A real, decodable 1x1 PNG.
final _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

Future<void> _pump(WidgetTester tester, SolvingProgressParams params) {
  return tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: SolvingProgressOrganism(params: params)),
      ),
    ),
  );
}

void main() {
  testWidgets(
      'shows the photo, a spinner, the title, the time so far and the body',
      (tester) async {
    await _pump(
      tester,
      SolvingProgressParams(
        imageBytes: _pngBytes,
        title: 'Solving your photo',
        body: 'This can take a while.',
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Solving your photo'), findsOneWidget);
    expect(find.byType(ElapsedTimeAtom), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);
    expect(find.text('This can take a while.'), findsOneWidget);
  });

  testWidgets('without a photo, shows no thumbnail', (tester) async {
    await _pump(
      tester,
      const SolvingProgressParams(
        title: 'Solving your photo',
        body: 'This can take a while.',
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.text('Solving your photo'), findsOneWidget);
  });
}
