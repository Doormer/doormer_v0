import 'dart:typed_data';

import 'package:doormer/src/features/questions/utils/photo/heic_detection.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _ftyp(String brand) => Uint8List.fromList([
      0,
      0,
      0,
      0x18,
      ...'ftyp'.codeUnits,
      ...brand.codeUnits,
      0,
      0,
      0,
      0,
    ]);

void main() {
  test('spots HEIC by file extension, in any case', () {
    expect(looksLikeHeic(fileName: 'IMG_1.HEIC'), isTrue);
    expect(looksLikeHeic(fileName: 'scan.heif'), isTrue);
  });

  test('spots HEIC by MIME type', () {
    expect(looksLikeHeic(mimeType: 'image/heic'), isTrue);
    expect(looksLikeHeic(mimeType: 'IMAGE/HEIF'), isTrue);
    expect(looksLikeHeic(mimeType: 'image/heic-sequence'), isTrue);
  });

  test('spots HEIC by the brand in its first bytes', () {
    for (final brand in const ['heic', 'heix', 'hevc', 'mif1']) {
      expect(looksLikeHeic(bytes: _ftyp(brand)), isTrue, reason: brand);
    }
  });

  test('does not mistake JPG, PNG or short files for HEIC', () {
    expect(looksLikeHeic(fileName: 'a.jpg', mimeType: 'image/jpeg'), isFalse);
    expect(looksLikeHeic(bytes: Uint8List.fromList([0x89, 0x50, 0x4E, 0x47])),
        isFalse);
    expect(looksLikeHeic(bytes: _ftyp('isom')), isFalse);
    expect(looksLikeHeic(), isFalse);
  });
}
