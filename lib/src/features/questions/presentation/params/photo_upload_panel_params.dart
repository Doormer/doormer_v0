import 'package:doormer/src/features/questions/presentation/mapper/photo_upload_presenter.dart';
import 'package:flutter/foundation.dart';

class PhotoUploadPanelParams {
  final Uint8List? imageBytes;
  final String? fileName;
  final bool isLoading;

  /// Button labels, resolved above this layer because they change with state —
  /// including whether the submit button is sending or resending.
  final PhotoUploadCopy copy;

  final VoidCallback onPickPhoto;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  const PhotoUploadPanelParams({
    this.imageBytes,
    this.fileName,
    required this.isLoading,
    required this.copy,
    required this.onPickPhoto,
    required this.onSubmit,
    required this.onClear,
  });
}
