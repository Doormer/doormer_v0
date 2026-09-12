import 'dart:math' as math;

import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/idle_beat_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The mint XP tag pinned to a card's corner.
///
/// Tilted so it reads as something stuck on afterwards — a reward attached to
/// the work, not a field printed on the card. It drops onto the card when the
/// card arrives, then wiggles a few times to be noticed, because a reward that
/// appears silently is not read as a reward.
class XpStickerAtom extends StatefulWidget {
  static const double _restAngle = 3;

  final String label;

  const XpStickerAtom({super.key, required this.label});

  @override
  State<XpStickerAtom> createState() => _XpStickerAtomState();
}

class _XpStickerAtomState extends State<XpStickerAtom>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drop;

  @override
  void initState() {
    super.initState();
    _drop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 690),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && MotionPolicy.of(context)) _drop.forward();
    });
  }

  @override
  void dispose() {
    _drop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!MotionPolicy.of(context)) {
      // The sticker is the reward, not the animation of the reward. With
      // motion off it is simply on the card, tilted, from the first frame.
      return Transform.rotate(
        angle: XpStickerAtom._restAngle * math.pi / 180,
        child: _tag(),
      );
    }
    return IdleBeatAtom(
      period: const Duration(milliseconds: 3400),
      beats: 3,
      // Waits for the drop to land: a sticker cannot settle and fidget at once.
      delay: const Duration(milliseconds: 750),
      child: _tag(),
      builder: (context, phase, child) => AnimatedBuilder(
        animation: _drop,
        child: child,
        builder: (context, child) => _dropped(phase, child!),
      ),
    );
  }

  /// Thrown on from above and overshooting slightly, so it reads as landing
  /// rather than fading up.
  Widget _dropped(double phase, Widget child) {
    final v = _drop.value;
    // 140ms of the 690ms run is the wait before it is thrown.
    final t = ((v * 690 - 140) / 550).clamp(0.0, 1.0);
    if (v == 0) {
      return Opacity(opacity: 0, child: child);
    }
    final landed = t >= 1;
    final wiggle = landed ? _wiggle(phase) : null;
    final angle = landed
        ? wiggle!.$1
        : t < 0.6
            ? _lerp(-14, 4, t / 0.6)
            : _lerp(4, XpStickerAtom._restAngle, (t - 0.6) / 0.4);
    final lift = landed
        ? wiggle!.$2
        : t < 0.6
            ? _lerp(-14, 2, t / 0.6)
            : _lerp(2, 0, (t - 0.6) / 0.4);
    final scale =
        t < 0.6 ? _lerp(0.7, 1.04, t / 0.6) : _lerp(1.04, 1, (t - 0.6) / 0.4);
    return Opacity(
      opacity: t.clamp(0.0, 1.0) == 0 ? 0 : (t / 0.35).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, lift),
        child: Transform.rotate(
          angle: angle * math.pi / 180,
          child: Transform.scale(scale: scale, child: child),
        ),
      ),
    );
  }

  /// A there-and-back tilt: 3 degrees out to -5 and back, lifting slightly at
  /// the far end.
  (double, double) _wiggle(double phase) {
    final swing = math.sin(phase * 2 * math.pi);
    final out = (1 - math.cos(phase * 2 * math.pi)) / 2;
    return (_lerp(XpStickerAtom._restAngle, -5, out), -2 * out * swing.abs());
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  Widget _tag() {
    return Container(
      key: const Key('step_xp_sticker'),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: QuestPalette.mint,
        borderRadius: BorderRadius.circular(7.r),
        boxShadow: [
          BoxShadow(
            color: QuestPalette.mint.withValues(alpha: 0.35),
            blurRadius: 14,
          ),
        ],
      ),
      child: Text(
        widget.label,
        style: TextStyle(
          fontFamily: kDisplayFont,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: QuestPalette.onMint,
          height: 1.2,
        ),
      ),
    );
  }
}
