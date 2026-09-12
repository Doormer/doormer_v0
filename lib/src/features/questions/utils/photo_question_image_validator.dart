import 'dart:typed_data';

class PhotoQuestionImageValidationResult {
  final String? contentType;
  final String? message;

  const PhotoQuestionImageValidationResult._({
    required this.contentType,
    required this.message,
  });

  bool get isValid => contentType != null;

  const PhotoQuestionImageValidationResult.valid(String contentType)
      : this._(contentType: contentType, message: null);

  const PhotoQuestionImageValidationResult.invalid(String message)
      : this._(contentType: null, message: message);
}

class PhotoQuestionImageValidator {
  static const int maxImageBytes = 10 * 1024 * 1024;
  static const String heicUnsupportedMessage =
      "HEIC isn't supported — please use JPEG or PNG.";
  static const String missingImageMessage =
      'Please choose a JPEG or PNG photo before submitting.';
  static const String oversizedImageMessage = 'Photo must be 10 MB or smaller.';
  static const String unsupportedImageMessage =
      'Only JPEG and PNG photos are supported.';

  static PhotoQuestionImageValidationResult validate({
    required Uint8List imageBytes,
    required String fileName,
    String? mimeType,
  }) {
    if (imageBytes.isEmpty) {
      return const PhotoQuestionImageValidationResult.invalid(
        missingImageMessage,
      );
    }

    if (imageBytes.lengthInBytes > maxImageBytes) {
      return const PhotoQuestionImageValidationResult.invalid(
        oversizedImageMessage,
      );
    }

    final normalizedMimeType = mimeType?.trim().toLowerCase();
    final extension = _extensionFor(fileName);

    if (_isHeic(extension, normalizedMimeType)) {
      return const PhotoQuestionImageValidationResult.invalid(
        heicUnsupportedMessage,
      );
    }

    if (normalizedMimeType == 'image/jpeg' ||
        extension == 'jpg' ||
        extension == 'jpeg') {
      return const PhotoQuestionImageValidationResult.valid('image/jpeg');
    }

    if (normalizedMimeType == 'image/png' || extension == 'png') {
      return const PhotoQuestionImageValidationResult.valid('image/png');
    }

    return const PhotoQuestionImageValidationResult.invalid(
      unsupportedImageMessage,
    );
  }

  static bool _isHeic(String extension, String? mimeType) {
    return extension == 'heic' ||
        extension == 'heif' ||
        mimeType == 'image/heic' ||
        mimeType == 'image/heif';
  }

  static String _extensionFor(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex + 1).trim().toLowerCase();
  }
}
