import 'dart:typed_data';

import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/features/questions/presentation/atoms/viewfinder_corners_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PhotoPreviewMolecule extends StatelessWidget {
  final Uint8List? imageBytes;

  const PhotoPreviewMolecule({super.key, this.imageBytes});

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytes;
    final cs = context.colorScheme;

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(16.r),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bytes == null)
              _buildEmptyHint(context)
            else
              Image.memory(bytes, fit: BoxFit.cover),
            const ViewfinderCornersAtom(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHint(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.document_scanner_outlined,
          size: 44.sp,
          color: cs.primary,
        ),
        SizedBox(height: 10.h),
        Text(
          'JPEG or PNG · max 10 MB',
          style: tt.bodyMedium?.copyWith(fontSize: 14.sp),
        ),
      ],
    );
  }
}
