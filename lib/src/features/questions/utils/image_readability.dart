import 'dart:typed_data';
import 'dart:ui' as ui;

const unreadableImageMessage = "We can't read this file. Try a JPG or PNG.";

/// Whether the browser can decode [bytes] as an image.
///
/// Run right after a pick, so a file the preview cannot draw (a HEIC on
/// desktop Chrome, a renamed PDF) is refused before it is shown.
Future<bool> isReadableImage(
  Uint8List bytes, {
  Future<void> Function(Uint8List bytes)? decode,
}) async {
  try {
    await (decode ?? _decode)(bytes);
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> _decode(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    final frame = await codec.getNextFrame();
    frame.image.dispose();
  } finally {
    codec.dispose();
  }
}
