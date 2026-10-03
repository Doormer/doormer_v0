@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_preparer.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_preparer_web.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_scaling.dart';
import 'package:doormer/src/features/questions/utils/photo/picked_photo_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

// A 40x20 JPEG (left half red, right half blue) made with Pillow, whose EXIF
// orientation is 6:
// "rotate 90° clockwise to display". Upright, it is 20 wide and 40 tall.
final _exifRotatedJpeg = base64Decode(
  '/9j/4AAQSkZJRgABAQAAAQABAAD/4QAiRXhpZgAASUkqAAgAAAABABIBAwABAAAABgAAAAAAAAD/'
  '2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUV'
  'DA8XGBYUGBIUFRT/2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQU'
  'FBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wAARCAAUACgDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEA'
  'AAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJx'
  'FDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNk'
  'ZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJ'
  'ytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQF'
  'BgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMz'
  'UvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3'
  'eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna'
  '4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD50ooor8MP9Uzgfir/AMwv/tr/AOyVwFd/'
  '8Vf+YX/21/8AZK4Cv9VPBP8A5IHL/wDuL/6dmf5r+L3/ACW2O/7h/wDpqAUUUV+5H44e+0UUV/hy'
  'f7FnA/FX/mF/9tf/AGSuAoor/VTwT/5IHL/+4v8A6dmf5r+L3/JbY7/uH/6agFFFFfuR+OH/2Q==',
);

Future<Uint8List> _canvasImage(int width, int height, String type) async {
  final canvas = web.HTMLCanvasElement()
    ..width = width
    ..height = height;
  final context = canvas.getContext('2d')! as web.CanvasRenderingContext2D;
  context
    ..fillStyle = '#ffffff'.toJS
    ..fillRect(0, 0, width, height)
    ..fillStyle = '#000000'.toJS
    ..font = '40px sans-serif'
    ..fillText('x^2 + 3x - 4 = 0', 100, 200);
  final done = Completer<web.Blob?>();
  canvas.toBlob(
    ((web.Blob? blob) => done.complete(blob)).toJS,
    type,
    0.9.toJS,
  );
  final blob = (await done.future)!;
  return (await blob.arrayBuffer().toDart).toDart.asUint8List();
}

Future<PhotoSize> _decodedSize(Uint8List bytes) async {
  final bitmap = await web.window
      .createImageBitmap(
        web.Blob(
          <JSAny>[bytes.toJS].toJS,
          web.BlobPropertyBag(type: 'image/jpeg'),
        ),
      )
      .toDart;
  try {
    return PhotoSize(bitmap.width, bitmap.height);
  } finally {
    bitmap.close();
  }
}

void main() {
  setUpAll(AppLogger.disable);

  test(
    'scales a large photo to fit 2048 px and saves it as JPEG',
    () async {
      final bytes = await _canvasImage(4000, 3000, 'image/jpeg');

      final photo = await WebPhotoPreparer().prepare(
        PickedPhotoFile(
          bytes: bytes,
          name: 'IMG_1.JPG',
          mimeType: 'image/jpeg',
        ),
      );

      expect(photo.width, 2048);
      expect(photo.height, 1536);
      expect(photo.fileName, 'IMG_1.jpg');
      expect(photo.mimeType, 'image/jpeg');
      expect(photo.bytes.sublist(0, 3), [0xFF, 0xD8, 0xFF]);
      expect(await _decodedSize(photo.bytes), const PhotoSize(2048, 1536));
    },
  );

  test(
    'keeps a small PNG at its size and saves it as JPEG',
    () async {
      final bytes = await _canvasImage(800, 600, 'image/png');

      final photo = await WebPhotoPreparer().prepare(
        PickedPhotoFile(
          bytes: bytes,
          name: 'notes.png',
          mimeType: 'image/png',
        ),
      );

      expect(photo.width, 800);
      expect(photo.height, 600);
      expect(photo.fileName, 'notes.jpg');
      expect(photo.bytes.sublist(0, 3), [0xFF, 0xD8, 0xFF]);
    },
  );

  test(
    'turns a photo the right way up using its EXIF rotation',
    () async {
      final photo = await WebPhotoPreparer().prepare(
        PickedPhotoFile(bytes: _exifRotatedJpeg, name: 'rotated.jpg'),
      );

      expect(photo.width, 20);
      expect(photo.height, 40);
    },
  );

  test(
    'refuses a file that is not an image',
    () async {
      final notAnImage = Uint8List.fromList(List.filled(64, 7));

      expect(
        WebPhotoPreparer().prepare(
          PickedPhotoFile(bytes: notAnImage, name: 'notes.png'),
        ),
        throwsA(
          isA<ValidationFailure>()
              .having((f) => f.message, 'message', photoUnreadableMessage),
        ),
      );
    },
  );

  test(
    'says the HEIC converter is unavailable when it cannot be loaded',
    () async {
      final heicHeader = Uint8List.fromList([
        0,
        0,
        0,
        0x18,
        ...'ftypheic'.codeUnits,
        ...List.filled(56, 0),
      ]);

      expect(
        WebPhotoPreparer(heicConverterUrl: '/no-such-converter.js').prepare(
          PickedPhotoFile(bytes: heicHeader, name: 'IMG_2.HEIC'),
        ),
        throwsA(
          isA<NetworkFailure>().having(
            (f) => f.message,
            'message',
            heicConverterUnavailableMessage,
          ),
        ),
      );
    },
  );
}
