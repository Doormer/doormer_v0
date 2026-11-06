import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Lays [children], each a tile such as a `TileAtom`, out [columns] to a
/// line, 12 apart. Every tile is as wide as the others, and as tall as the
/// tallest on its line. A line that isn't full keeps its tiles that width,
/// from the left.
class TileGridAtom extends StatelessWidget {
  /// The space between tiles, across and down, in design pixels.
  static const double gap = 12;

  final int columns;
  final List<Widget> children;

  const TileGridAtom({
    super.key,
    required this.columns,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var first = 0; first < children.length; first += columns) ...[
          if (first > 0) SizedBox(height: gap.h),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = first; i < first + columns; i++) ...[
                  if (i > first) SizedBox(width: gap.w),
                  Expanded(
                    child: i < children.length
                        ? children[i]
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
