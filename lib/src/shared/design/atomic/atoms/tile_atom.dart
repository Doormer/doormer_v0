import 'package:doormer/src/shared/design/atomic/atoms/surface_card_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One tile, as a `TileGridAtom` lays them out: [child] on a raised surface
/// with rounded corners.
///
/// With [onTap], the whole tile, its rim included, is one tap and hover
/// target, and its ink stays inside the rounded corners. A button on the
/// tile, such as a menu, still takes its own taps.
class TileAtom extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const TileAtom({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = 16.r;
    return SurfaceCardAtom(
      padding: EdgeInsets.zero,
      radius: radius,
      child: ClipRRect(
        // Inside the card's 1 px edge, so the ink's corners follow the card's.
        borderRadius: BorderRadius.circular(radius - 1),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: EdgeInsets.all(12.w), child: child),
          ),
        ),
      ),
    );
  }
}
