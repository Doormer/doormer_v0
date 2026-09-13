import 'dart:math' as math;

import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entity/card_rarity.dart';
import '../../domain/entity/draw_outcome.dart';
import '../atoms/card_back_atom.dart';
import '../atoms/collectible_card_atom.dart';
import '../params/reveal_params.dart';

/// The draw: a card lands face-down, tells its rarity, turns, and settles.
///
/// A common draw gets a soft settle and none of the flourish. That restraint is
/// the whole point — if every draw bloomed, none would feel like anything.
class CardRevealOrganism extends StatefulWidget {
  static const Duration totalDuration = Duration(milliseconds: 1600);

  final RevealParams params;

  const CardRevealOrganism({super.key, required this.params});

  /// Cards in the fan. Below the cap the fan *is* the count and can be read
  /// without the badge; at four it stops meaning a number and means *a pile*.
  /// Four is also the widest fan that fits a phone card without the outer
  /// cards leaving the frame.
  static int fanCountFor(int copies) => math.min(math.max(copies, 1), 4);

  /// How wide the glow should be at a given rotation, where 0 is face-down,
  /// 0.5 is edge-on and 1 is face-up.
  ///
  /// **This is the ghost-rectangle fix.** A glow that keeps its width while the
  /// card foreshortens is plainly visible at 90°, when the card itself has no
  /// width at all. Driving it from the same value collapses both together.
  static double glowScaleX(double rotation) {
    final foreshorten = (math.cos(rotation * math.pi)).abs();
    return math.max(foreshorten, 0.02);
  }

  @override
  State<CardRevealOrganism> createState() => CardRevealState();
}

class CardRevealState extends State<CardRevealOrganism>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// 0 face-down, 1 face-up.
  double get rotation => _flip.value;

  late final Animation<double> _flip;

  /// The headline's own arrival, after the flip has finished.
  late final Animation<double> _landing;

  /// How far the headline has arrived, 0 hidden to 1 fully shown.
  double get headlineOpacity => _landing.value;

  bool get _isRare => widget.params.outcome.card.rarity == Rarity.rare;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: CardRevealOrganism.totalDuration,
    );
    _flip = CurvedAnimation(
      parent: _controller,
      // Back 190ms, tell 450ms, then the flip, then the landing.
      curve: const Interval(0.4, 0.66, curve: Curves.easeInOutCubic),
    );
    // The headline waits for the flip to finish. Riding the flip's own midpoint
    // would announce the result while the card was still edge-on, which reads
    // as the app spoiling its own reveal.
    _landing = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.66, 0.85, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Duration.zero still *arrives*, which is what keeps the card face up
    // rather than frozen face down when motion is off.
    _controller.duration = MotionPolicy.duration(
      context,
      CardRevealOrganism.totalDuration,
    );
    if (!_controller.isAnimating && !_controller.isCompleted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outcome = widget.params.outcome;
    final showFlourish = _isRare && MotionPolicy.idle(context);

    return GestureDetector(
      onTap: widget.params.onDismiss,
      behavior: HitTestBehavior.opaque,
      child: ColoredBox(
        color: QuestPalette.night.withValues(alpha: 0.92),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _flip.value;
              final faceUp = t >= 0.5;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (showFlourish)
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..scale(CardRevealOrganism.glowScaleX(t), 1.0),
                          child: Container(
                            width: 140.w,
                            height: 210.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18.r),
                              boxShadow: [
                                BoxShadow(
                                  color: QuestPalette.amber
                                      .withValues(alpha: 0.55 * t),
                                  blurRadius: 60 * t,
                                  spreadRadius: 18 * t,
                                ),
                              ],
                            ),
                          ),
                        ),
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0011)
                          ..rotateY(t * math.pi),
                        child: faceUp
                            // Un-mirror the face once past edge-on.
                            ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(math.pi),
                                child: _fan(outcome),
                              )
                            : const CardBackAtom(width: 126),
                      ),
                    ],
                  ),
                  SizedBox(height: 18.h),
                  Opacity(
                    opacity: _landing.value,
                    child: Text(
                      outcome.kind.headline,
                      style: TextStyle(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w800,
                        color: _headlineColour(outcome),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Color _headlineColour(DrawOutcome outcome) {
    switch (outcome.kind) {
      case DrawResultKind.newCard:
        return QuestPalette.mint;
      case DrawResultKind.upgrade:
        return QuestPalette.amber;
      case DrawResultKind.duplicate:
        return QuestPalette.body;
    }
  }

  /// One card, or a fan when more than one is held. Angles widen with the
  /// count, so the fan grows in spread rather than only in depth.
  Widget _fan(DrawOutcome outcome) {
    final count = CardRevealOrganism.fanCountFor(outcome.copiesAfter);
    const spreads = <int, List<double>>{
      1: [],
      2: [-8],
      3: [-13, 13],
      4: [-19, -7, 9],
    };

    return Stack(
      alignment: Alignment.center,
      children: [
        for (final angle in spreads[count]!)
          Transform.rotate(
            alignment: Alignment.bottomCenter,
            angle: angle * math.pi / 180,
            child: Opacity(
              opacity: 0.45,
              child: CollectibleCardAtom(
                card: outcome.card,
                width: 126,
                showScale: false,
                copies: 1,
              ),
            ),
          ),
        CollectibleCardAtom(
          card: outcome.card,
          width: 126,
          copies: outcome.copiesAfter,
        ),
      ],
    );
  }
}
