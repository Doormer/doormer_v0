import 'dart:typed_data';

const _heicExtensions = {'heic', 'heif'};

const _heicMimeTypes = {
  'image/heic',
  'image/heif',
  'image/heic-sequence',
  'image/heif-sequence',
};

/// The `ftyp` brands HEIC and HEIF files start with.
const _heicBrands = {
  'heic',
  'heix',
  'hevc',
  'hevx',
  'heim',
  'heis',
  'hevm',
  'hevs',
  'mif1',
  'msf1',
};

/// Whether a file is probably HEIC/HEIF, judged by its name, its MIME type or
/// its first bytes. Any one of them is enough.
bool looksLikeHeic({String? fileName, String? mimeType, Uint8List? bytes}) {
  final name = fileName?.trim().toLowerCase() ?? '';
  final dot = name.lastIndexOf('.');
  if (dot != -1 && _heicExtensions.contains(name.substring(dot + 1))) {
    return true;
  }
  if (_heicMimeTypes.contains(mimeType?.trim().toLowerCase())) return true;
  if (bytes != null &&
      bytes.length >= 12 &&
      String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp') {
    return _heicBrands.contains(String.fromCharCodes(bytes.sublist(8, 12)));
  }
  return false;
}
