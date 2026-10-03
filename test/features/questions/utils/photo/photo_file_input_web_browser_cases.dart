@TestOn('browser')
library;

import 'package:doormer/src/features/questions/utils/photo/photo_file_input.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_file_input_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

web.HTMLInputElement? _fileInput() =>
    web.document.querySelector('input[type=file]') as web.HTMLInputElement?;

void main() {
  test('the gallery chooser accepts JPG, PNG and HEIC, with no capture',
      () async {
    final picked = WebPhotoFileInput().pick(fromCamera: false);

    final input = _fileInput()!;
    expect(input.accept, galleryPhotoAccept);
    expect(input.hasAttribute('capture'), isFalse);

    input.dispatchEvent(web.Event('cancel'));
    expect(await picked, isNull);
    expect(_fileInput(), isNull);
  });

  test("the camera chooser asks for the phone's back camera", () async {
    final picked = WebPhotoFileInput().pick(fromCamera: true);

    final input = _fileInput()!;
    expect(input.accept, cameraPhotoAccept);
    expect(input.getAttribute('capture'), cameraCapture);

    input.dispatchEvent(web.Event('cancel'));
    expect(await picked, isNull);
  });

  test('a new pick replaces a chooser that never reported back', () async {
    final input = WebPhotoFileInput();
    input.pick(fromCamera: false).ignore();
    final second = input.pick(fromCamera: false);

    expect(web.document.querySelectorAll('input[type=file]').length, 1);

    _fileInput()!.dispatchEvent(web.Event('cancel'));
    expect(await second, isNull);
  });
}
