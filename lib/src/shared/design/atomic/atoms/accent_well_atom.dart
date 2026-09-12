import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A dark well with a coloured rail down its left edge.
///
/// Used for the two insets that interrupt prose — a math block and a solver
/// caveat — so both read as "set apart", with the rail colour saying which
/// kind of aside it is.
///
/// The rail is a painted strip rather than a [Border] side. A [BoxDecoration]
/// with a `borderRadius` and a non-uniform [Border] compiles and analyzes
/// clean, then throws `A borderRadius can only be given on borders with
/// uniform colors` the first time it paints.
class AccentWellAtom extends StatelessWidget {
  static const Color wellColor = Color(0xB3000000);

  final Color accent;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double railWidth;

  const AccentWellAtom({
    super.key,
    required this.accent,
    required this.child,
    this.padding,
    this.margin,
    this.railWidth = 4,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10.r);

    return Container(
      width: double.infinity,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: ColoredBox(
          color: wellColor,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: railWidth.w,
                child: ColoredBox(color: accent),
              ),
              Padding(
                padding: padding ?? EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
