import 'package:flutter/foundation.dart';

class PhotoUploadPanelParams {
  final Uint8List? imageBytes;
  final String? fileName;
  final bool isLoading;
  final VoidCallback onPickPhoto;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  const PhotoUploadPanelParams({
    this.imageBytes,
    this.fileName,
    required this.isLoading,
    required this.onPickPhoto,
    required this.onSubmit,
    required this.onClear,
  });
}
