import 'package:doormer/src/shared/design/atomic/atoms/surface_card_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shows [children] as tiles, [columns] to a line, each on its own raised
/// surface. Every tile is as wide as the others, and as tall as the tallest
/// on its line. A line that isn't full keeps its tiles that width, from the
/// left.
class TileGridAtom extends StatelessWidget {
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
          if (first > 0) SizedBox(height: 12.h),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = first; i < first + columns; i++) ...[
                  if (i > first) SizedBox(width: 12.w),
                  Expanded(
                    child: i < children.length
                        ? SurfaceCardAtom(
                            padding: EdgeInsets.all(12.w),
                            radius: 16.r,
                            child: children[i],
                          )
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
