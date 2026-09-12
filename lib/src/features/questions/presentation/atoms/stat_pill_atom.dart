import 'dart:math' as math;

import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/idle_beat_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A small stat pill — the XP total, the streak.
///
/// Colour is the meaning: mint for what has been banked, amber for what is at
/// stake. Nothing else on the page may use those two for anything else.
class StatPillAtom extends StatefulWidget {
  /// The pop, and the flame's flare, when the streak comes under threat.
  static const Duration stakeDuration = Duration(milliseconds: 800);

  /// The pill finishes settling before the emblem has finished arriving.
  static const Duration popDuration = Duration(milliseconds: 700);

  final IconData icon;

  /// Marks the icon so something can be aimed at the pill's emblem rather than
  /// at the pill's centre, which drifts as the label's digits grow.
  final Key? iconKey;
  final String label;
  final Color accent;

  /// Bobs the emblem a few times on arrival. Reserved for a stat that is a
  /// living thing rather than a running total — a streak can be lost, and the
  /// flicker is what says so.
  final bool alive;

  /// The moment the stat is genuinely at risk. The pill swells once and the
  /// emblem flares back in, so the student is told the stakes have changed at
  /// the point they change — not left to infer it from a colour they have been
  /// looking at since the page loaded.
  final bool atStake;

  const StatPillAtom({
    super.key,
    required this.icon,
    this.iconKey,
    required this.label,
    required this.accent,
    this.alive = false,
    this.atStake = false,
  });

  @override
  State<StatPillAtom> createState() => _StatPillAtomState();
}

double get _stakeMs => StatPillAtom.stakeDuration.inMilliseconds.toDouble();
double get _popMs => StatPillAtom.popDuration.inMilliseconds.toDouble();

class _StatPillAtomState extends State<StatPillAtom>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stake;

  @override
  void initState() {
    super.initState();
    _stake = AnimationController(
      vsync: this,
      duration: StatPillAtom.stakeDuration,
      value: 1,
    );
  }

  @override
  void didUpdateWidget(StatPillAtom oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.atStake == oldWidget.atStake) return;
    if (!widget.atStake || !MotionPolicy.of(context)) {
      _stake.value = 1;
      return;
    }
    _stake.forward(from: 0);
  }

  @override
  void dispose() {
    _stake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: widget.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: widget.accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _emblem(),
          SizedBox(width: 4.w),
          Text(
            widget.label,
            style: TextStyle(
              fontFamily: kDisplayFont,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: widget.accent,
              height: 1.1,
            ),
          ),
        ],
      ),
    );

    return AnimatedBuilder(
      animation: _stake,
      builder: (context, child) {
        // The pop is shorter than the flare, so it runs over the first
        // 700ms of the 800ms the emblem takes, and is done while the flame
        // is still arriving.
        final p = (_stake.value * _stakeMs / _popMs).clamp(0.0, 1.0);
        if (p == 1) return child!;
        // Out fast, back slow. The swell peaks early so the pill is already
        // settling by the time the student's eye arrives, which reads as a
        // flinch rather than as the pill changing size.
        final swell = p < 0.4
            ? const Cubic(.34, 1.56, .64, 1).transform(p / 0.4)
            : 1 - (p - 0.4) / 0.6;
        return Transform.scale(
          key: const Key('pill_pop'),
          scale: 1 + 0.10 * swell,
          child: child,
        );
      },
      child: pill,
    );
  }

  Widget _emblem() {
    final icon = Icon(widget.icon,
        key: widget.iconKey, size: 12.sp, color: widget.accent);

    return AnimatedBuilder(
      animation: _stake,
      builder: (context, child) {
        final settled = _stake.value == 1;
        // The flame stops bobbing to be re-lit, and only picks the idle back
        // up once it has arrived. Two motions at once on one small glyph read
        // as a glitch rather than as either of the things they mean.
        final body = widget.alive && settled ? _bob(child!) : child!;
        if (settled) return body;

        final t = const Cubic(.3, 1.4, .5, 1).transform(_stake.value);
        return FadeTransition(
          key: const Key('pill_flare'),
          opacity: AlwaysStoppedAnimation<double>(t.clamp(0.0, 1.0)),
          child: Transform.rotate(
            angle: (1 - t) * -20 * math.pi / 180,
            child: Transform.scale(scale: 0.4 + 0.6 * t, child: body),
          ),
        );
      },
      child: icon,
    );
  }

  Widget _bob(Widget icon) {
    return IdleBeatAtom(
      period: const Duration(milliseconds: 1500),
      beats: 4,
      child: icon,
      builder: (context, phase, child) {
        // Up and over, then back: a flame leans as it rises.
        final rise = (1 - math.cos(phase * 2 * math.pi)) / 2;
        final lean = math.sin(phase * 2 * math.pi);
        return Transform.translate(
          offset: Offset(0, -3 * rise),
          child:
              Transform.rotate(angle: lean * 6 * math.pi / 180, child: child),
        );
      },
    );
  }
}
