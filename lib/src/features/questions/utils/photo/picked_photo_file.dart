import 'dart:typed_data';

/// A photo file as the student chose it, before any preparation.
class PickedPhotoFile {
  final Uint8List bytes;
  final String name;
  final String? mimeType;

  const PickedPhotoFile({
    required this.bytes,
    required this.name,
    this.mimeType,
  });
}

/// A photo ready to show and upload: upright, scaled down and saved as JPEG.
class PreparedPhoto {
  final Uint8List bytes;
  final String fileName;
  final int width;
  final int height;

  const PreparedPhoto({
    required this.bytes,
    required this.fileName,
    required this.width,
    required this.height,
  });

  String get mimeType => 'image/jpeg';
}

/// [name] with its extension changed to `.jpg`, or `photo.jpg` when there is
/// no usable name.
String preparedFileNameFor(String name) {
  final trimmed = name.trim();
  final dot = trimmed.lastIndexOf('.');
  if (trimmed.isEmpty || dot == 0) return 'photo.jpg';
  final stem = dot == -1 ? trimmed : trimmed.substring(0, dot);
  return '$stem.jpg';
}
