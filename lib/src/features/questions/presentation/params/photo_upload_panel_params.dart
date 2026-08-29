import 'package:doormer/src/features/questions/presentation/mapper/photo_upload_presenter.dart';
import 'package:flutter/foundation.dart';

class PhotoUploadPanelParams {
  final Uint8List? imageBytes;
  final String? fileName;
  final bool isLoading;

  /// True once a failed solve has left this photo in place, so the button
  /// below it is resending rather than sending.
  final bool isRetry;

  /// Button labels, resolved above this layer because they change with state.
  final PhotoUploadCopy copy;

  final VoidCallback onPickPhoto;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  const PhotoUploadPanelParams({
    this.imageBytes,
    this.fileName,
    required this.isLoading,
    this.isRetry = false,
    required this.copy,
    required this.onPickPhoto,
    required this.onSubmit,
    required this.onClear,
  });
}
