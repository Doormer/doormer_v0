import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StatusActionRowMolecule extends StatelessWidget {
  final VoidCallback onRetake;
  final VoidCallback onTypeInstead;

  const StatusActionRowMolecule({
    super.key,
    required this.onRetake,
    required this.onTypeInstead,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButtonAtom(
            label: 'Retake',
            onPressed: onRetake,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: AppButtonAtom(
            label: 'Type instead',
            variant: AppButtonVariant.outlined,
            borderColor: AppColors.focusedBorders,
            onPressed: onTypeInstead,
          ),
        ),
      ],
    );
  }
}
