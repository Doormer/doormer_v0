import 'dart:math' as math;

import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';

/// A one-shot burst of falling paper.
///
/// It runs once and stops. Confetti that keeps falling stops being a
/// celebration and becomes weather.
class ConfettiAtom extends StatefulWidget {
  static const int pieceCount = 30;
  static const Duration fall = Duration(milliseconds: 1500);

  /// Seeded so a test can assert where the paper goes. Production leaves it
  /// null and every burst is different.
  final int? seed;

  const ConfettiAtom({super.key, this.seed});

  @override
  State<ConfettiAtom> createState() => _ConfettiAtomState();
}

class _ConfettiAtomState extends State<ConfettiAtom>
    with SingleTickerProviderStateMixin {
  static const List<Color> _colours = [
    QuestPalette.pink,
    QuestPalette.mint,
    QuestPalette.violet,
    QuestPalette.amber,
  ];

  late final AnimationController _controller;
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    // Total run is the fall plus the latest stagger, so the controller ends
    // when the last piece has actually landed.
    _controller = AnimationController(
      vsync: this,
      duration: ConfettiAtom.fall * 1.5,
    );
    final random = math.Random(widget.seed);
    _pieces = List<_Piece>.generate(
      ConfettiAtom.pieceCount,
      (i) => _Piece(
        left: random.nextDouble(),
        delay: random.nextDouble() / 3,
        colour: _colours[i % _colours.length],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && MotionPolicy.of(context)) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final v = _controller.value;
          if (v == 0 || v == 1) return const SizedBox.shrink();
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final piece in _pieces) _build(piece, v, width),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _build(_Piece piece, double v, double width) {
    final t = ((v - piece.delay) / (1 / 1.5)).clamp(0.0, 1.0);
    if (t == 0 || t == 1) return const SizedBox.shrink();
    // Gravity, not a glide: paper leaves slowly and arrives fast.
    final fallen = Curves.easeIn.transform(t);
    return Positioned(
      left: piece.left * width,
      top: -18 + fallen * 260,
      child: Opacity(
        opacity: 1 - t,
        child: Transform.rotate(
          angle: fallen * 640 * math.pi / 180,
          child: Container(
            width: 8,
            height: 13,
            decoration: BoxDecoration(
              color: piece.colour,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

class _Piece {
  final double left;
  final double delay;
  final Color colour;

  const _Piece({
    required this.left,
    required this.delay,
    required this.colour,
  });
}
