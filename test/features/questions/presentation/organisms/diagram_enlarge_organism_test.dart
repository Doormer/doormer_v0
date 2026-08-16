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

Widget _sheet({bool motion = true}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: !motion),
        child: DiagramEnlargeOrganism(
          visual: _visual,
          onClose: () {},
          imageProviderBuilder: (_) => MemoryImage(_pngBytes),
        ),
      ),
    ),
  );
}

double _backdropOpacity(WidgetTester tester) {
  var opacity = 1.0;
  for (final e in tester
      .widgetList<FadeTransition>(find.byType(FadeTransition))
      .toList()) {
    opacity *= e.opacity.value;
  }
  return opacity;
}

/// Where the sheet actually sits on screen, not what its animation says.
double _cardTop(WidgetTester tester) {
  return tester.getTopLeft(find.byKey(const Key('enlarge_close'))).dy;
}

void _entranceTests() {
  group('the sheet entrance', () {
    testWidgets('closes over the page rather than cutting to it',
        (tester) async {
      await tester.pumpWidget(_sheet());
      // The controller starts in a post-frame callback, so the first pump only
      // schedules it; sampling now would read the zeroth tick.
      await tester.pump();

      expect(_backdropOpacity(tester), lessThan(0.1),
          reason: 'the page behind must still be visible as it goes');

      await tester.pump(const Duration(milliseconds: 120));
      final mid = _backdropOpacity(tester);
      expect(mid, greaterThan(0.1));
      expect(mid, lessThan(1.0));

      await tester.pumpAndSettle();
      expect(_backdropOpacity(tester), 1.0);
    });

    testWidgets('rises into place instead of appearing at rest',
        (tester) async {
      await tester.pumpWidget(_sheet());
      await tester.pump();

      final start = _cardTop(tester);

      await tester.pump(const Duration(milliseconds: 120));
      final mid = _cardTop(tester);

      await tester.pumpAndSettle();
      final settled = _cardTop(tester);

      expect(start, greaterThan(settled + 20),
          reason: 'the figure comes up from below, as the design has it');
      expect(mid, lessThan(start));
      expect(mid, greaterThan(settled));
    });

    testWidgets('the backdrop closes before the figure has finished arriving',
        (tester) async {
      await tester.pumpWidget(_sheet());
      await tester.pump();

      // Stepped in small increments: one long pump would jump the controller
      // straight to its end value and every intermediate frame would be lost.
      double? topWhenCovered;
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 10));
        if (topWhenCovered == null && _backdropOpacity(tester) >= 0.999) {
          topWhenCovered = _cardTop(tester);
        }
      }
      await tester.pumpAndSettle();

      expect(topWhenCovered, isNotNull);
      expect(topWhenCovered!, greaterThan(_cardTop(tester)),
          reason: 'the step text must be gone before the figure lands on top '
              'of where it was');
    });

    testWidgets('is simply already here under reduced motion', (tester) async {
      await tester.pumpWidget(_sheet(motion: false));
      await tester.pump();
      final arrived = _cardTop(tester);
      final shown = _backdropOpacity(tester);

      await tester.pumpWidget(_sheet(motion: false));
      await tester.pumpAndSettle();

      expect(shown, 1.0, reason: 'never held at zero opacity');
      expect(arrived, moreOrLessEquals(_cardTop(tester), epsilon: 0.01));
    });
  });
}

void main() {
  _entranceTests();

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
