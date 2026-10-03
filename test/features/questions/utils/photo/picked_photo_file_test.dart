import 'dart:typed_data';

import 'package:doormer/src/features/questions/utils/photo/picked_photo_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('preparedFileNameFor', () {
    test('changes the extension to .jpg', () {
      expect(preparedFileNameFor('IMG_1234.HEIC'), 'IMG_1234.jpg');
      expect(preparedFileNameFor('algebra.png'), 'algebra.jpg');
      expect(preparedFileNameFor('scan.final.jpeg'), 'scan.final.jpg');
    });

    test('adds .jpg to a name without an extension', () {
      expect(preparedFileNameFor('camera-upload'), 'camera-upload.jpg');
    });

    test('falls back to photo.jpg when there is no usable name', () {
      expect(preparedFileNameFor(''), 'photo.jpg');
      expect(preparedFileNameFor('   '), 'photo.jpg');
      expect(preparedFileNameFor('.heic'), 'photo.jpg');
    });
  });

  test('a prepared photo is always a JPEG', () {
    final photo = PreparedPhoto(
      bytes: Uint8List(0),
      fileName: 'photo.jpg',
      width: 1,
      height: 1,
    );

    expect(photo.mimeType, 'image/jpeg');
  });
}
