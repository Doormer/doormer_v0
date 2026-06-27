import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PhotoActionRowMolecule extends StatelessWidget {
  final bool hasPhoto;
  final bool isLoading;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const PhotoActionRowMolecule({
    super.key,
    required this.hasPhoto,
    required this.isLoading,
    required this.onPick,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButtonAtom(
            label: hasPhoto ? 'Retake' : 'Choose photo',
            icon: Icons.photo_camera_outlined,
            onPressed: isLoading ? null : onPick,
          ),
        ),
        if (hasPhoto) ...[
          SizedBox(width: 12.w),
          AppButtonAtom(
            label: 'Clear',
            variant: AppButtonVariant.outlined,
            borderColor: AppColors.borders,
            onPressed: isLoading ? null : onClear,
          ),
        ],
      ],
    );
  }
}
