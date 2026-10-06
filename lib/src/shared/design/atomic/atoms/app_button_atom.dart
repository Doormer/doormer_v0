import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum AppButtonVariant { filled, accent, outlined }

class AppButtonAtom extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  /// Shown next to the spinner while [isLoading]. Without it the spinner
  /// stands alone, which is enough for a quick wait but says nothing during
  /// a long one.
  final String? loadingLabel;
  final bool expand;
  final Color? borderColor;

  const AppButtonAtom({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.isLoading = false,
    this.loadingLabel,
    this.expand = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    final padding = EdgeInsets.symmetric(
      horizontal: 18.w,
      vertical: 14.h,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20.r),
    );

    final Color spinnerColor;
    if (variant == AppButtonVariant.outlined) {
      spinnerColor = cs.primary;
    } else if (variant == AppButtonVariant.accent) {
      spinnerColor = cs.onTertiary;
    } else {
      spinnerColor = cs.onPrimary;
    }

    final Widget spinner = SizedBox(
      height: 20.h,
      width: 20.w,
      child: CircularProgressIndicator(
        strokeWidth: 2.w,
        color: spinnerColor,
      ),
    );
    final busyLabel = loadingLabel;
    final Widget content = !isLoading
        ? Text(label)
        : busyLabel == null
            ? spinner
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  spinner,
                  SizedBox(width: 10.w),
                  Flexible(
                    child: Text(busyLabel, overflow: TextOverflow.ellipsis),
                  ),
                ],
              );

    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;

    // A loading button is untappable, so Flutter would paint it with its
    // disabled colours. The spinner is coloured for the enabled background,
    // so keep that background while loading or the spinner disappears into
    // the disabled grey.
    Widget button;
    if (variant == AppButtonVariant.outlined) {
      final style = OutlinedButton.styleFrom(
        foregroundColor: cs.primary,
        disabledForegroundColor: isLoading ? cs.primary : null,
        side: BorderSide(color: borderColor ?? cs.outlineVariant),
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
    } else if (variant == AppButtonVariant.accent) {
      final style = FilledButton.styleFrom(
        backgroundColor: cs.tertiary,
        foregroundColor: cs.onTertiary,
        disabledBackgroundColor: isLoading ? cs.tertiary : null,
        disabledForegroundColor: isLoading ? cs.onTertiary : null,
        padding: padding,
        shape: shape,
      );
      button = icon == null
          ? FilledButton(
              onPressed: effectiveOnPressed,
              style: style,
              child: content,
            )
          : FilledButton.icon(
              onPressed: effectiveOnPressed,
              style: style,
              icon: Icon(icon),
              label: content,
            );
    } else {
      final style = FilledButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        disabledBackgroundColor: isLoading ? cs.primary : null,
        disabledForegroundColor: isLoading ? cs.onPrimary : null,
        padding: padding,
        shape: shape,
      );
      button = icon == null
          ? FilledButton(
              onPressed: effectiveOnPressed,
              style: style,
              child: content,
            )
          : FilledButton.icon(
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
