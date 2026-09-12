import 'package:doormer/src/features/questions/presentation/mapper/photo_upload_presenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('names the picker by whether there is a photo to replace', () {
    expect(
      photoUploadCopyFor(hasPhoto: false, isRetry: false).pickLabel,
      'Choose photo',
    );
    expect(
      photoUploadCopyFor(hasPhoto: true, isRetry: false).pickLabel,
      'Retake',
    );
  });

  test('names the send button by whether it is a resend', () {
    expect(
      photoUploadCopyFor(hasPhoto: true, isRetry: false).submitLabel,
      'Submit to solver',
    );
    expect(
      photoUploadCopyFor(hasPhoto: true, isRetry: true).submitLabel,
      'Try again',
    );
  });
}
