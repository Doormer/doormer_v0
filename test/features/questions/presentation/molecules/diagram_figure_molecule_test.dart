import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/atoms/diagram_atom.dart';
import 'package:doormer/src/features/questions/presentation/molecules/diagram_figure_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1x1 transparent PNG.
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
  alt: 'A right triangle formed by the 5 m vertical separation.',
);

class _FailingImageProvider extends MemoryImage {
  _FailingImageProvider() : super(_pngBytes);

  @override
  ImageStreamCompleter loadImage(MemoryImage key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.error(Exception('403 expired SAS URL')),
    );
  }
}

/// Fails the first [failures] loads, then serves the real bytes.
class _FlakyImageProvider extends MemoryImage {
  static int attempts = 0;

  final int failures;

  _FlakyImageProvider(this.failures) : super(_pngBytes);

  @override
  ImageStreamCompleter loadImage(MemoryImage key, ImageDecoderCallback decode) {
    attempts++;
    if (attempts <= failures) {
      return OneFrameImageStreamCompleter(
        Future<ImageInfo>.error(Exception('dropped request')),
      );
    }
    return super.loadImage(key, decode);
  }
}

/// Never resolves, standing in for a diagram still on the wire.
class _PendingImageProvider extends MemoryImage {
  _PendingImageProvider() : super(_pngBytes);

  @override
  ImageStreamCompleter loadImage(MemoryImage key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
  }
}

/// Walks past every retry the atom is allowed, so what is on screen afterwards
/// is the figure's final answer rather than a moment mid-recovery.
Future<void> _settleRetries(WidgetTester tester) async {
  for (var i = 0; i < DiagramAtom.maxAttempts + 1; i++) {
    await tester.pump();
    await tester.pump();
    await tester.pump(DiagramAtom.retryBackoff);
  }
  await tester.pump();
}

Widget _pump({required DiagramImageProviderBuilder builder}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SizedBox(
          width: 358,
          child: DiagramFigureMolecule(
            visual: _visual,
            onEnlarge: () {},
            imageProviderBuilder: builder,
          ),
        ),
      ),
    ),
  );
}

void main() {
  // A cached success from an earlier test would be served without the provider
  // ever being asked, so the retry counts would read zero.
  setUp(() {
    _FlakyImageProvider.attempts = 0;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets('reserves the payload aspect ratio and shows the caption',
      (tester) async {
    await tester.pumpWidget(_pump(builder: (_) => MemoryImage(_pngBytes)));
    await tester.pump();

    final aspect = tester.widget<AspectRatio>(
      find.descendant(
        of: find.byKey(const Key('diagram_figure')),
        matching: find.byType(AspectRatio),
      ),
    );
    expect(aspect.aspectRatio, closeTo(1600 / 1067, 0.0001));

    expect(
      find.text('The 5 m and 4 m measurements determine the road angle.'),
      findsOneWidget,
    );
  });

  testWidgets('applies the verified invert plus hue-rotate ink filter',
      (tester) async {
    await tester.pumpWidget(_pump(builder: (_) => MemoryImage(_pngBytes)));
    await tester.pump();

    final filtered = tester.widget<ColorFiltered>(
      find.descendant(
        of: find.byKey(const Key('diagram_image')),
        matching: find.byType(ColorFiltered),
      ),
    );
    expect(filtered.colorFilter, DiagramAtom.inkFilter);
  });

  testWidgets('turns while the diagram is still on its way', (tester) async {
    await tester.pumpWidget(_pump(builder: (_) => _PendingImageProvider()));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('diagram_spinner')), findsOneWidget);

    // And it is bounded: an endless spinner would hang this call, and with it
    // every future test that renders a loading diagram.
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('diagram_spinner')), findsOneWidget,
        reason: 'the diagram has still not arrived, so the slot stays');
  });

  testWidgets('holds on through a dropped request instead of giving up',
      (tester) async {
    await tester.pumpWidget(_pump(builder: (_) => _FlakyImageProvider(1)));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('diagram_spinner')), findsOneWidget,
        reason: 'the figure is still on its way, not gone');
    expect(find.byKey(const Key('diagram_figure')), findsOneWidget);

    await _settleRetries(tester);

    expect(find.byKey(const Key('diagram_figure')), findsOneWidget,
        reason: 'one dropped request must not cost the student the diagram');
    expect(
      find.text('The 5 m and 4 m measurements determine the road angle.'),
      findsOneWidget,
    );
  });

  testWidgets('tries three times before it gives up', (tester) async {
    await tester.pumpWidget(_pump(builder: (_) => _FlakyImageProvider(99)));
    await _settleRetries(tester);

    expect(_FlakyImageProvider.attempts, 3);
    expect(DiagramAtom.maxAttempts, 3);
  });

  testWidgets('collapses the image and the caption together on load failure',
      (tester) async {
    await tester.pumpWidget(_pump(builder: (_) => _FailingImageProvider()));
    await _settleRetries(tester);

    expect(find.byKey(const Key('diagram_figure')), findsNothing);
    expect(find.byKey(const Key('diagram_caption')), findsNothing);
    expect(
      find.text('The 5 m and 4 m measurements determine the road angle.'),
      findsNothing,
    );
  });

  testWidgets('resets failure state when the visual changes to a different URL',
      (tester) async {
    const visual1 = VisualSolutionSegment(
      mediaType: 'image/png',
      url: 'https://example.test/step1.png',
      width: 1600,
      height: 1067,
      caption: 'Caption for step one.',
      alt: 'Step one diagram.',
    );
    const visual2 = VisualSolutionSegment(
      mediaType: 'image/png',
      url: 'https://example.test/step2.png',
      width: 1600,
      height: 1067,
      caption: 'Caption for step two.',
      alt: 'Step two diagram.',
    );

    const widgetKey = ValueKey<int>(1);

    Widget buildWith({
      required VisualSolutionSegment visual,
      required DiagramImageProviderBuilder builder,
    }) {
      return ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: SizedBox(
              width: 358,
              child: DiagramFigureMolecule(
                key: widgetKey,
                visual: visual,
                onEnlarge: () {},
                imageProviderBuilder: builder,
              ),
            ),
          ),
        ),
      );
    }

    // First: failing provider → figure collapses.
    await tester.pumpWidget(
      buildWith(visual: visual1, builder: (_) => _FailingImageProvider()),
    );
    await _settleRetries(tester);

    expect(find.byKey(const Key('diagram_figure')), findsNothing,
        reason: 'figure must collapse after load failure');

    // Second: same key position, different URL, succeeding provider → renders.
    await tester.pumpWidget(
      buildWith(visual: visual2, builder: (_) => MemoryImage(_pngBytes)),
    );
    await tester.pump();

    expect(find.byKey(const Key('diagram_figure')), findsOneWidget,
        reason: 'figure must appear again after visual URL changes');
  });

  testWidgets('tapping the figure requests enlargement', (tester) async {
    var enlarged = 0;

    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SizedBox(
            width: 358,
            child: DiagramFigureMolecule(
              visual: _visual,
              onEnlarge: () => enlarged++,
              imageProviderBuilder: (_) => MemoryImage(_pngBytes),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();

    await tester.tap(find.byKey(const Key('diagram_figure')));
    await tester.pump();

    expect(enlarged, 1);
  });
}
