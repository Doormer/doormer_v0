import 'dart:typed_data';

import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:doormer/src/features/questions/presentation/atoms/viewfinder_corners_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PhotoPreviewMolecule extends StatelessWidget {
  final Uint8List? imageBytes;

  const PhotoPreviewMolecule({super.key, this.imageBytes});

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytes;

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.focusedBorders),
          borderRadius: BorderRadius.circular(16.r),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bytes == null)
              _buildEmptyHint()
            else
              Image.memory(bytes, fit: BoxFit.cover),
            const ViewfinderCornersAtom(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHint() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.document_scanner_outlined,
          size: 44.sp,
          color: AppColors.primary,
        ),
        SizedBox(height: 10.h),
        Text(
          'JPEG or PNG · max 10 MB',
          style: AppTextStyles.bodyMedium.copyWith(fontSize: 14.sp),
        ),
      ],
    );
  }
}
