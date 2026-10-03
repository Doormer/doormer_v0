import 'dart:async';
import 'dart:js_interop';

import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_file_input.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_preparer.dart';
import 'package:doormer/src/features/questions/utils/photo/picked_photo_file.dart';
import 'package:web/web.dart' as web;

class WebPhotoFileInput implements PhotoFileInput {
  /// The chooser still waiting for an answer. Some browsers never report a
  /// cancel, so the next pick removes it rather than letting inputs pile up.
  web.HTMLInputElement? _openInput;

  @override
  bool get usesNativeCamera =>
      web.window.matchMedia('(pointer: coarse)').matches;

  @override
  Future<PickedPhotoFile?> pick({required bool fromCamera}) {
    _openInput?.remove();

    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = fromCamera ? cameraPhotoAccept : galleryPhotoAccept;
    input.style.display = 'none';
    if (fromCamera) input.setAttribute('capture', cameraCapture);

    final result = Completer<PickedPhotoFile?>();
    void finish() {
      input.remove();
      if (identical(_openInput, input)) _openInput = null;
    }

    input.addEventListener(
      'change',
      ((web.Event _) {
        final file = input.files?.item(0);
        finish();
        if (file == null) {
          result.complete(null);
        } else {
          unawaited(
            _read(file).then(result.complete, onError: result.completeError),
          );
        }
      }).toJS,
    );
    input.addEventListener(
      'cancel',
      ((web.Event _) {
        finish();
        if (!result.isCompleted) result.complete(null);
      }).toJS,
    );

    web.document.body!.append(input);
    _openInput = input;
    input.click();
    return result.future;
  }

  Future<PickedPhotoFile> _read(web.File file) async {
    try {
      final buffer = await file.arrayBuffer().toDart;
      return PickedPhotoFile(
        bytes: buffer.toDart.asUint8List(),
        name: file.name,
        mimeType: file.type.isEmpty ? null : file.type,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Chosen photo could not be read',
        error: e,
        stackTrace: stackTrace,
      );
      throw ValidationFailure(photoUnreadableMessage);
    }
  }
}
