import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum AppButtonVariant { filled, accent, outlined }

class AppButtonAtom extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final Color? borderColor;

  const AppButtonAtom({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.symmetric(vertical: 14.h);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.r),
    );

    final Widget content = isLoading
        ? SizedBox(
            height: 20.h,
            width: 20.w,
            child: CircularProgressIndicator(
              strokeWidth: 2.w,
              color: AppColors.onPrimary,
            ),
          )
        : Text(label);

    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;

    Widget button;
    if (variant == AppButtonVariant.outlined) {
      final style = OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: borderColor ?? AppColors.borders),
        padding: padding,
        shape: shape,
      );
      button = icon == null
          ? OutlinedButton(
              onPressed: effectiveOnPressed,
              style: style,
              child: content,
            )
          : OutlinedButton.icon(
              onPressed: effectiveOnPressed,
              style: style,
              icon: Icon(icon),
              label: content,
            );
    } else {
      final backgroundColor = variant == AppButtonVariant.accent
          ? AppColors.accent
          : AppColors.primary;
      final style = ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: AppColors.onPrimary,
        padding: padding,
        shape: shape,
      );
      button = icon == null
          ? ElevatedButton(
              onPressed: effectiveOnPressed,
              style: style,
              child: content,
            )
          : ElevatedButton.icon(
              onPressed: effectiveOnPressed,
              style: style,
              icon: Icon(icon),
              label: content,
            );
    }

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
