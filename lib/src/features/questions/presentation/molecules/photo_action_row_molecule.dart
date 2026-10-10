import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PhotoActionRowMolecule extends StatelessWidget {
  final bool hasPhoto;
  final bool isLoading;

  /// Named above this layer, because what the picker does depends on whether
  /// there is already a photo to replace.
  final String pickLabel;

  final VoidCallback onPick;
  final VoidCallback onClear;

  /// Opens the crop & rotate screen. Null hides the button.
  final VoidCallback? onEdit;

  const PhotoActionRowMolecule({
    super.key,
    required this.hasPhoto,
    required this.isLoading,
    required this.pickLabel,
    required this.onPick,
    required this.onClear,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButtonAtom(
            label: pickLabel,
            icon: hasPhoto ? null : Icons.photo_camera_outlined,
            variant:
                hasPhoto ? AppButtonVariant.outlined : AppButtonVariant.filled,
            onPressed: isLoading ? null : onPick,
          ),
        ),
        if (hasPhoto) ...[
          if (onEdit != null) ...[
            SizedBox(width: 12.w),
            IconButton.outlined(
              tooltip: 'Crop & rotate',
              icon: const Icon(Icons.crop_rotate),
              onPressed: isLoading ? null : onEdit,
            ),
          ],
          SizedBox(width: 12.w),
          AppButtonAtom(
            label: 'Clear',
            variant: AppButtonVariant.outlined,
            onPressed: isLoading ? null : onClear,
          ),
        ],
      ],
    );
  }
}
