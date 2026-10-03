import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/utils/photo/heic_detection.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_preparer.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_scaling.dart';
import 'package:doormer/src/features/questions/utils/photo/picked_photo_file.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:web/web.dart' as web;

/// High enough that letter edges stay crisp for the solver.
const double _jpegQuality = 0.92;

/// Relative to the page's `<base href>`; `flutter build web` copies `web/` as is.
const String _heicConverterPath = 'vendor/heic-to/heic-to.js';

class WebPhotoPreparer implements PhotoPreparer {
  WebPhotoPreparer({
    String? heicConverterUrl,
    @visibleForTesting
    FutureOr<Uint8List> Function(web.HTMLCanvasElement canvas)? encodeJpeg,
  })  : _heicConverterUrl = heicConverterUrl,
        _encodeJpegOverride = encodeJpeg;

  final String? _heicConverterUrl;
  final FutureOr<Uint8List> Function(web.HTMLCanvasElement canvas)?
      _encodeJpegOverride;

  /// Loaded on first need and kept; reset after a failed load so the next
  /// HEIC photo can try again.
  Future<_HeicToModule>? _heicConverter;
  int _failedHeicConverterLoads = 0;

  @override
  Future<PreparedPhoto> prepare(PickedPhotoFile file) async {
    final blob = web.Blob(
      <JSAny>[file.bytes.toJS].toJS,
      web.BlobPropertyBag(type: file.mimeType ?? ''),
    );
    final bitmap = await _decode(blob, file);
    try {
      return await _scaleAndEncode(bitmap, preparedFileNameFor(file.name));
    } on Failure {
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Photo could not be prepared',
        error: e,
        stackTrace: stackTrace,
      );
      throw ValidationFailure(photoUnreadableMessage);
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

  Future<_HeicToModule> _loadHeicConverter() {
    final pending = _heicConverter;
    if (pending != null) return pending;

    late final Future<_HeicToModule> loading;
    loading = _importHeicConverter().catchError(
      (Object e, StackTrace stackTrace) {
        if (identical(_heicConverter, loading)) {
          _heicConverter = null;
          _failedHeicConverterLoads += 1;
        }
        AppLogger.error(
          'HEIC converter could not be loaded',
          error: e,
          stackTrace: stackTrace,
        );
        throw NetworkFailure(heicConverterUnavailableMessage);
      },
    );
    _heicConverter = loading;
    return loading;
  }

  Future<_HeicToModule> _importHeicConverter() async {
    final url = _heicConverterUrl ??
        Uri.parse(web.document.baseURI).resolve(_heicConverterPath).toString();
    final module = await importModule(_heicConverterImportUrl(url).toJS).toDart;
    return module as _HeicToModule;
  }

  String _heicConverterImportUrl(String url) {
    if (_failedHeicConverterLoads == 0) return url;

    final uri = Uri.parse(url);
    final queryParameters =
        Map<String, List<String>>.from(uri.queryParametersAll);
    queryParameters['retry'] = [_failedHeicConverterLoads.toString()];
    return uri.replace(queryParameters: queryParameters).toString();
  }

  Future<PreparedPhoto> _scaleAndEncode(
    web.ImageBitmap bitmap,
    String fileName,
  ) async {
    web.CanvasImageSource source = bitmap;
    web.HTMLCanvasElement? canvas;
    var didFinishScaling = false;
    try {
      for (final step in scalingSteps(PhotoSize(bitmap.width, bitmap.height))) {
        final next = web.HTMLCanvasElement();
        var didDraw = false;
        try {
          next
            ..width = step.width
            ..height = step.height;
          final context =
              next.getContext('2d')! as web.CanvasRenderingContext2D;
          context
            ..imageSmoothingEnabled = true
            ..imageSmoothingQuality = 'high'
            ..fillStyle = '#ffffff'.toJS
            ..fillRect(0, 0, step.width, step.height)
            ..drawImage(source, 0, 0, step.width, step.height);
          didDraw = true;
        } finally {
          if (!didDraw) _release(next);
        }
        if (canvas != null) _release(canvas);
        canvas = next;
        source = next;
      }
      didFinishScaling = true;
    } finally {
      if (!didFinishScaling && canvas != null) _release(canvas);
    }

    final last = canvas!;
    try {
      return PreparedPhoto(
        bytes: await _encodeJpegWithOverride(last),
        fileName: fileName,
        width: last.width,
        height: last.height,
      );
    } finally {
      _release(last);
    }
  }

  Future<Uint8List> _encodeJpegWithOverride(
    web.HTMLCanvasElement canvas,
  ) async {
    final encodeJpeg = _encodeJpegOverride;
    if (encodeJpeg != null) return await encodeJpeg(canvas);
    return _encodeJpeg(canvas);
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
