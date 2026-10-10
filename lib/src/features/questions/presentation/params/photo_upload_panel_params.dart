import 'package:doormer/src/features/questions/presentation/mapper/photo_upload_presenter.dart';
import 'package:flutter/foundation.dart';

class PhotoUploadPanelParams {
  final Uint8List? imageBytes;
  final String? fileName;
  final bool isLoading;
  final bool showWhenEmpty;

  /// A chosen photo is being prepared; nothing can be picked, cleared or
  /// submitted until it is ready.
  final bool isPreparing;

  /// Button labels, resolved above this layer because they change with state —
  /// including whether the submit button is sending or resending.
  final PhotoUploadCopy copy;

  final VoidCallback onPickPhoto;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  /// Opens the crop & rotate screen on the photo on screen. Null when the
  /// photo cannot be edited, which hides the button.
  final VoidCallback? onEditPhoto;

  const PhotoUploadPanelParams({
    this.imageBytes,
    this.fileName,
    required this.isLoading,
    this.showWhenEmpty = false,
    this.isPreparing = false,
    required this.copy,
    required this.onPickPhoto,
    required this.onSubmit,
    required this.onClear,
    this.onEditPhoto,
  });
}
