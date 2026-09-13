import 'dart:math' as math;

import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entity/holding.dart';
import '../atoms/collectible_card_atom.dart';

/// A held card in the grid, sitting on a tilted stack when more than one copy
/// is held.
///
/// The tilt is the same gesture the reveal fan uses, tightened to grid size:
/// rotation has meant *more than one* everywhere in this feature. Offsetting
/// instead was tried and fails — at 104px a 5px offset is a line, and reads as
/// a drop shadow rather than a card.
class CardTileMolecule extends StatefulWidget {
  final Holding holding;
  final double width;
  final VoidCallback? onTap;

  const CardTileMolecule({
    super.key,
    required this.holding,
    required this.width,
    this.onTap,
  });

  /// Layers *behind* the front card. Capped at two: the grid answers
  /// "one, a couple, or a pile" and the badge answers "how many".
  static int layersFor(int copies) => anglesFor(copies).length;

  /// The rear layers' angles, **ordered back to front**.
  ///
  /// A pair opens to 3°; three or more splay to 5° and 2.5°. The list order is
  /// the paint order, and in a [Stack] later children paint on top — so the
  /// steepest angle must come first or the deepest card ends up in front of
  /// the shallower one.
  static List<double> anglesFor(int copies) {
    if (copies <= 1) return const [];
    if (copies == 2) return const [3.0];
    return const [5.0, 2.5];
  }

  @override
  State<CardTileMolecule> createState() => _CardTileMoleculeState();
}

class _CardTileMoleculeState extends State<CardTileMolecule> {
  /// "Tap opens; 5px lift on press" — the spec's own words for this gesture.
  static const double _pressLift = 5;
  static const Duration _pressDuration = Duration(milliseconds: 120);

  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final copies = widget.holding.totalCopies;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedContainer(
        duration: MotionPolicy.duration(context, _pressDuration),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          0,
          _pressed ? -_pressLift.h : 0,
          0,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Painted first so they sit behind the art but above the surface,
            // and in back-to-front order so the steepest tilt is deepest.
            for (final angle in CardTileMolecule.anglesFor(copies))
              Transform.rotate(
                alignment: Alignment.bottomCenter,
                angle: angle * math.pi / 180,
                child: Container(
                  width: widget.width.w,
                  height: widget.width.w / CollectibleCardAtom.aspectRatio,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2450),
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 9,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
            CollectibleCardAtom(
              card: widget.holding.card,
              width: widget.width,
              copies: copies,
            ),
          ],
        ),
      ),
    );
  }
}
