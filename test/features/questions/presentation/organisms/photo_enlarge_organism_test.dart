import 'dart:convert';
import 'dart:typed_data';

import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/organisms/photo_enlarge_organism.dart';
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

Widget _sheet({
  required String? photoUrl,
  required VoidCallback onClose,
  ImageProvider Function(String url)? image,
}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: PhotoEnlargeOrganism(
        photoUrl: photoUrl,
        onClose: onClose,
        imageProviderBuilder: image ?? (_) => MemoryImage(_pngBytes),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the photo with a close button', (tester) async {
    var closes = 0;
    await tester.pumpWidget(_sheet(
      photoUrl: 'https://example.test/photo/42.jpg',
      onClose: () => closes++,
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('photo_enlarge_image')), findsOneWidget);
    await tester.tap(find.byKey(const Key('enlarge_close')));
    expect(closes, 1);
  });

  testWidgets('shows an image icon and stays open when the photo will not load',
      (tester) async {
    var closes = 0;
    await tester.pumpWidget(_sheet(
      photoUrl: 'https://example.test/photo/42.jpg',
      onClose: () => closes++,
      image: (_) => _FailingImageProvider(),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('photo_enlarge_unavailable')), findsOneWidget);
    expect(closes, 0, reason: 'a photo that fails must not close the sheet');
    expect(find.byKey(const Key('enlarge_close')), findsOneWidget);
  });

  testWidgets('shows an image icon when the photo has no link', (tester) async {
    await tester.pumpWidget(_sheet(photoUrl: null, onClose: () {}));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('photo_enlarge_unavailable')), findsOneWidget);
    expect(find.byKey(const Key('photo_enlarge_image')), findsNothing);
  });
}
