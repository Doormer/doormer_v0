import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/utils/photo/heic_detection.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_preparer.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_scaling.dart';
import 'package:doormer/src/features/questions/utils/photo/picked_photo_file.dart';
import 'package:web/web.dart' as web;

/// High enough that letter edges stay crisp for the solver.
const double _jpegQuality = 0.92;

/// Relative to the page's `<base href>`; `flutter build web` copies `web/` as is.
const String _heicConverterPath = 'vendor/heic-to/heic-to.js';

class WebPhotoPreparer implements PhotoPreparer {
  WebPhotoPreparer({String? heicConverterUrl})
      : _heicConverterUrl = heicConverterUrl;

  final String? _heicConverterUrl;

  /// Loaded on first need and kept; reset after a failed load so the next
  /// HEIC photo can try again.
  Future<_HeicToModule>? _heicConverter;

  @override
  Future<PreparedPhoto> prepare(PickedPhotoFile file) async {
    final blob = web.Blob(
      <JSAny>[file.bytes.toJS].toJS,
      web.BlobPropertyBag(type: file.mimeType ?? ''),
    );
    final bitmap = await _decode(blob, file);
    try {
      return await _scaleAndEncode(bitmap, preparedFileNameFor(file.name));
    } finally {
      bitmap.close();
    }
  }

  /// The browser's own decoder first: it is fast and covers JPG, PNG, and HEIC
  /// on Safari 17+. Only a HEIC it cannot read goes to the converter.
  Future<web.ImageBitmap> _decode(web.Blob blob, PickedPhotoFile file) async {
    try {
      return await web.window
          .createImageBitmap(
            blob,
            web.ImageBitmapOptions(imageOrientation: 'from-image'),
          )
          .toDart;
    } catch (e, stackTrace) {
      final isHeic = looksLikeHeic(
        fileName: file.name,
        mimeType: file.mimeType,
        bytes: file.bytes,
      );
      if (!isHeic) {
        AppLogger.error(
          'Photo could not be decoded',
          error: e,
          stackTrace: stackTrace,
        );
        throw ValidationFailure(photoUnreadableMessage);
      }
    }

    final converter = await _loadHeicConverter();
    try {
      return await converter
          .heicTo(_HeicToOptions(blob: blob, type: 'bitmap'))
          .toDart;
    } catch (e, stackTrace) {
      AppLogger.error(
        'HEIC photo could not be decoded',
        error: e,
        stackTrace: stackTrace,
      );
      throw ValidationFailure(photoUnreadableMessage);
    }
  }

  Future<_HeicToModule> _loadHeicConverter() async {
    final pending = _heicConverter ??= _importHeicConverter();
    try {
      return await pending;
    } catch (e, stackTrace) {
      _heicConverter = null;
      AppLogger.error(
        'HEIC converter could not be loaded',
        error: e,
        stackTrace: stackTrace,
      );
      throw NetworkFailure(heicConverterUnavailableMessage);
    }
  }

  Future<_HeicToModule> _importHeicConverter() async {
    final url = _heicConverterUrl ??
        Uri.parse(web.document.baseURI).resolve(_heicConverterPath).toString();
    final module = await importModule(url.toJS).toDart;
    return module as _HeicToModule;
  }

  Future<PreparedPhoto> _scaleAndEncode(
    web.ImageBitmap bitmap,
    String fileName,
  ) async {
    web.CanvasImageSource source = bitmap;
    web.HTMLCanvasElement? canvas;
    for (final step in scalingSteps(PhotoSize(bitmap.width, bitmap.height))) {
      final next = web.HTMLCanvasElement()
        ..width = step.width
        ..height = step.height;
      final context = next.getContext('2d')! as web.CanvasRenderingContext2D;
      context
        ..imageSmoothingEnabled = true
        ..imageSmoothingQuality = 'high'
        ..fillStyle = '#ffffff'.toJS
        ..fillRect(0, 0, step.width, step.height)
        ..drawImage(source, 0, 0, step.width, step.height);
      if (canvas != null) _release(canvas);
      canvas = next;
      source = next;
    }

    final last = canvas!;
    try {
      return PreparedPhoto(
        bytes: await _encodeJpeg(last),
        fileName: fileName,
        width: last.width,
        height: last.height,
      );
    } finally {
      _release(last);
    }
  }

  Future<Uint8List> _encodeJpeg(web.HTMLCanvasElement canvas) async {
    final done = Completer<web.Blob?>();
    canvas.toBlob(
      ((web.Blob? blob) => done.complete(blob)).toJS,
      'image/jpeg',
      _jpegQuality.toJS,
    );
    final blob = await done.future;
    if (blob == null) {
      AppLogger.error('Photo could not be saved as JPEG');
      throw ValidationFailure(photoUnreadableMessage);
    }
    final buffer = await blob.arrayBuffer().toDart;
    return buffer.toDart.asUint8List();
  }

  /// Safari keeps a canvas's memory until its size is zeroed, and a phone
  /// runs out after a few full-size photos.
  void _release(web.HTMLCanvasElement canvas) {
    canvas
      ..width = 0
      ..height = 0;
  }
}

extension type _HeicToModule._(JSObject _) implements JSObject {
  external JSPromise<web.ImageBitmap> heicTo(_HeicToOptions options);
}

extension type _HeicToOptions._(JSObject _) implements JSObject {
  external factory _HeicToOptions({web.Blob blob, String type});
}
