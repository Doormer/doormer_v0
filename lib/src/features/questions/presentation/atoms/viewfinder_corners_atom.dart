import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ViewfinderCornersAtom extends StatelessWidget {
  const ViewfinderCornersAtom({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _corner(top: 12.h, left: 12.w),
        _corner(top: 12.h, right: 12.w, flipX: true),
        _corner(bottom: 12.h, left: 12.w, flipY: true),
        _corner(bottom: 12.h, right: 12.w, flipX: true, flipY: true),
      ],
    );
  }

  Widget _corner({
    double? top,
    double? right,
    double? bottom,
    double? left,
    bool flipX = false,
    bool flipY = false,
  }) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: SizedBox(
        width: 32.w,
        height: 32.h,
        child: Stack(
          children: [
            Positioned(
              top: flipY ? null : 0,
              bottom: flipY ? 0 : null,
              left: 0,
              right: 0,
              child: Container(height: 3.h, color: AppColors.accent),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: flipX ? null : 0,
              right: flipX ? 0 : null,
              child: Container(width: 3.w, color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}
