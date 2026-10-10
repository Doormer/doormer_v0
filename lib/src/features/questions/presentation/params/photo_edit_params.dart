import 'package:doormer/src/features/questions/utils/photo/photo_edit.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_scaling.dart';
import 'package:flutter/foundation.dart';

/// What the crop & rotate screen shows, and what its controls do.
class PhotoEditParams {
  /// The upright photo with no edit applied.
  final Uint8List imageBytes;
  final PhotoSize imageSize;
  final PhotoEdit edit;

  final ValueChanged<PhotoEdit> onEditChanged;
  final VoidCallback onTurnLeft;
  final VoidCallback onTurnRight;

  /// Null when there is nothing to reset.
  final VoidCallback? onReset;
  final VoidCallback onCancel;
  final VoidCallback onUsePhoto;

  const PhotoEditParams({
    required this.imageBytes,
    required this.imageSize,
    required this.edit,
    required this.onEditChanged,
    required this.onTurnLeft,
    required this.onTurnRight,
    required this.onReset,
    required this.onCancel,
    required this.onUsePhoto,
  });
}
