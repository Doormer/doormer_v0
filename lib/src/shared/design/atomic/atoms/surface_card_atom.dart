import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SurfaceCardAtom extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;

  const SurfaceCardAtom({
    super.key,
    required this.child,
    this.padding,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borders),
        borderRadius: BorderRadius.circular(radius ?? 18.r),
      ),
      child: child,
    );
  }
}
