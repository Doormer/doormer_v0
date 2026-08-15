import 'dart:convert';
import 'dart:typed_data';

import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/organisms/diagram_enlarge_organism.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

final Uint8List _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

const _visual = VisualSolutionSegment(
  mediaType: 'image/png',
  url: 'https://example.test/step1.png',
  width: 1600,
  height: 1067,
  caption: 'The 5 m and 4 m measurements determine the road angle.',
  alt: 'A right triangle.',
);

void main() {
  testWidgets('shows the caption and closes on the close button',
      (tester) async {
    var closed = 0;

    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.dark,
        home: DiagramEnlargeOrganism(
          visual: _visual,
          onClose: () => closed++,
          imageProviderBuilder: (_) => MemoryImage(_pngBytes),
        ),
      ),
    ));
    await tester.pump();

    expect(
      find.text('The 5 m and 4 m measurements determine the road angle.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('enlarge_close')));
    await tester.pump();

    expect(closed, 1);
  });

  testWidgets('the backdrop is fully opaque', (tester) async {
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.dark,
        home: DiagramEnlargeOrganism(
          visual: _visual,
          onClose: () {},
          imageProviderBuilder: (_) => MemoryImage(_pngBytes),
        ),
      ),
    ));
    await tester.pump();

    final backdrop = tester.widget<DecoratedBox>(
      find.byKey(const Key('enlarge_backdrop')),
    );
    final gradient =
        (backdrop.decoration as BoxDecoration).gradient as RadialGradient;

    for (final color in gradient.colors) {
      expect(color.a, 1.0, reason: 'no step text may bleed through');
    }
  });
}
