import 'package:flutter/foundation.dart';

class PhotoUploadPanelParams {
  final Uint8List? imageBytes;
  final String? fileName;
  final bool isLoading;

  /// True once a failed solve has left this photo in place, so the button
  /// below it is resending rather than sending.
  final bool isRetry;
  final VoidCallback onPickPhoto;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  const PhotoUploadPanelParams({
    this.imageBytes,
    this.fileName,
    required this.isLoading,
    this.isRetry = false,
    required this.onPickPhoto,
    required this.onSubmit,
    required this.onClear,
  });
}
