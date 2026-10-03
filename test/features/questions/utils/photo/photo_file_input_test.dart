import 'package:doormer/src/features/questions/utils/photo/photo_file_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the gallery accepts JPG, PNG and HEIC by type and by extension', () {
    final accepted = galleryPhotoAccept.split(',');

    expect(
      accepted,
      containsAll(['image/jpeg', 'image/png', 'image/heic', 'image/heif']),
    );
    expect(
      accepted,
      containsAll(['.jpg', '.jpeg', '.png', '.heic', '.heif']),
    );
  });

  test("the camera asks the phone's own camera app for the back camera", () {
    expect(cameraPhotoAccept, 'image/*');
    expect(cameraCapture, 'environment');
  });
}
