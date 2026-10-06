import 'dart:convert';
import 'dart:typed_data';

import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/atoms/photo_thumbnail_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1x1 transparent PNG.
final Uint8List _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// An image whose link has expired.
class _FailingImageProvider extends MemoryImage {
  _FailingImageProvider() : super(_pngBytes);

  @override
  ImageStreamCompleter loadImage(MemoryImage key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.error(Exception('403 expired SAS URL')),
    );
  }
}

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: Center(child: child)),
      ),
    );

const _fallback = Key('photo_thumbnail_fallback');

void main() {
  testWidgets('shows a plain tile when there is no thumbnail', (tester) async {
    await tester
        .pumpWidget(_host(const PhotoThumbnailAtom(url: null, size: 80)));

    expect(find.byKey(_fallback), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('shows the photo when there is one', (tester) async {
    await tester.pumpWidget(_host(PhotoThumbnailAtom(
      url: 'https://example.test/thumbnail/42.jpg',
      size: 80,
      imageProviderBuilder: (_) => MemoryImage(_pngBytes),
    )));

    expect(find.byType(Image), findsOneWidget);
    expect(find.byKey(_fallback), findsNothing);
  });

  testWidgets('shows a plain tile when the photo will not load',
      (tester) async {
    await tester.pumpWidget(_host(PhotoThumbnailAtom(
      url: 'https://example.test/thumbnail/42.jpg',
      size: 80,
      imageProviderBuilder: (_) => _FailingImageProvider(),
    )));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(_fallback), findsOneWidget);
  });

  testWidgets('is a square of the size it is given', (tester) async {
    await tester
        .pumpWidget(_host(const PhotoThumbnailAtom(url: null, size: 80)));

    expect(tester.getSize(find.byType(PhotoThumbnailAtom)), const Size(80, 80));
  });
}
