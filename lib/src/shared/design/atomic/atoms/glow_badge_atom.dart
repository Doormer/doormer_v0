import 'package:flutter/material.dart';

/// A round badge holding [icon] in [color], on a soft wash of that colour,
/// with a glow of it around the edge. Toasts, confirmations and the friends
/// card before setup lead with one.
class GlowBadgeAtom extends StatelessWidget {
  final IconData icon;
  final Color color;

  /// The badge's diameter, in logical pixels.
  final double size;

  final double iconSize;

  /// How far the glow reaches past the edge.
  final double glowRadius;

  const GlowBadgeAtom({
    super.key,
    required this.icon,
    required this.color,
    required this.size,
    required this.iconSize,
    required this.glowRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
        boxShadow: [
          // Outer only, so the glow rings the badge without brightening its
          // fill.
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: glowRadius,
            blurStyle: BlurStyle.outer,
          ),
        ],
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}
