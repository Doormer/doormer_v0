import 'dart:typed_data';

import 'package:doormer/src/features/questions/utils/photo_question_image_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhotoQuestionImageValidator', () {
    test('accepts JPEG files by extension and returns image/jpeg', () {
      final result = PhotoQuestionImageValidator.validate(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'algebra.JPG',
        mimeType: null,
      );

      expect(result.isValid, isTrue);
      expect(result.contentType, 'image/jpeg');
      expect(result.message, isNull);
    });

    test('accepts PNG files by mime type and returns image/png', () {
      final result = PhotoQuestionImageValidator.validate(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'camera-upload',
        mimeType: 'image/png',
      );

      expect(result.isValid, isTrue);
      expect(result.contentType, 'image/png');
      expect(result.message, isNull);
    });

    test('rejects files larger than 10MB before upload', () {
      final result = PhotoQuestionImageValidator.validate(
        imageBytes: Uint8List(PhotoQuestionImageValidator.maxImageBytes + 1),
        fileName: 'large.png',
        mimeType: 'image/png',
      );

      expect(result.isValid, isFalse);
      expect(result.contentType, isNull);
      expect(result.message, 'Photo must be 10 MB or smaller.');
    });

    test('rejects HEIC files by extension with a helpful message', () {
      final result = PhotoQuestionImageValidator.validate(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'homework.heic',
        mimeType: null,
      );

      expect(result.isValid, isFalse);
      expect(result.contentType, isNull);
      expect(
        result.message,
        "HEIC isn't supported — please use JPEG or PNG.",
      );
    });

    test('rejects HEIC files by mime type with a helpful message', () {
      final result = PhotoQuestionImageValidator.validate(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'camera-upload',
        mimeType: 'image/heif',
      );

      expect(result.isValid, isFalse);
      expect(result.contentType, isNull);
      expect(
        result.message,
        "HEIC isn't supported — please use JPEG or PNG.",
      );
    });
  });
}
