import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/atoms/photo_thumbnail_atom.dart';
import 'package:flutter/foundation.dart';
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

/// An image already downloaded, which shows at once.
class _DownloadedImageProvider extends ImageProvider<_DownloadedImageProvider> {
  final ui.Image image;

  _DownloadedImageProvider(this.image);

  @override
  Future<_DownloadedImageProvider> obtainKey(
          ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _DownloadedImageProvider key,
    ImageDecoderCallback decode,
  ) =>
      OneFrameImageStreamCompleter(
          SynchronousFuture(ImageInfo(image: image.clone())));
}

/// An image still downloading.
class _DownloadingImageProvider
    extends ImageProvider<_DownloadingImageProvider> {
  @override
  Future<_DownloadingImageProvider> obtainKey(
          ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _DownloadingImageProvider key,
    ImageDecoderCallback decode,
  ) =>
      OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
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
        .pumpWidget(_host(const PhotoThumbnailAtom(url: null, height: 80)));

    expect(find.byKey(_fallback), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('shows the photo when there is one', (tester) async {
    await tester.pumpWidget(_host(PhotoThumbnailAtom(
      url: 'https://example.test/thumbnail/42.jpg',
      height: 80,
      imageProviderBuilder: (_) => MemoryImage(_pngBytes),
    )));

    expect(find.byType(Image), findsOneWidget);
    expect(find.byKey(_fallback), findsNothing);
  });

  testWidgets('shows a plain tile when the photo will not load',
      (tester) async {
    await tester.pumpWidget(_host(PhotoThumbnailAtom(
      url: 'https://example.test/thumbnail/42.jpg',
      height: 80,
      imageProviderBuilder: (_) => _FailingImageProvider(),
    )));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(_fallback), findsOneWidget);
  });

  // Thumbnails are made 3:2, so a one-line question can run the full width.
  testWidgets('is three wide for every two high', (tester) async {
    await tester
        .pumpWidget(_host(const PhotoThumbnailAtom(url: null, height: 80)));

    expect(
        tester.getSize(find.byType(PhotoThumbnailAtom)), const Size(120, 80));
  });

  // A thumbnail of another shape, made before thumbnails were 3:2, must still
  // show the whole question rather than its middle.
  testWidgets('draws the whole thumbnail, never a crop of it', (tester) async {
    await tester.pumpWidget(_host(PhotoThumbnailAtom(
      url: 'https://example.test/thumbnail/42.jpg',
      height: 80,
      imageProviderBuilder: (_) => MemoryImage(_pngBytes),
    )));
    await tester.pump();

    expect(tester.widget<RawImage>(find.byType(RawImage)).fit, BoxFit.contain);
  });

  // The API signs a thumbnail's link afresh on each read, so a row read
  // again can come back with another link to the same photo.
  testWidgets('keeps showing the photo while a new link to it loads',
      (tester) async {
    final photo = await tester.runAsync(() => createTestImage(width: 3));
    await tester.pumpWidget(_host(PhotoThumbnailAtom(
      url: 'https://example.test/thumbnail/42.jpg?sig=monday',
      height: 80,
      imageProviderBuilder: (_) => _DownloadedImageProvider(photo!),
    )));
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);

    await tester.pumpWidget(_host(PhotoThumbnailAtom(
      url: 'https://example.test/thumbnail/42.jpg?sig=tuesday',
      height: 80,
      imageProviderBuilder: (_) => _DownloadingImageProvider(),
    )));

    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull,
        reason: 'the photo stays on show until the new link loads');
  });
}
