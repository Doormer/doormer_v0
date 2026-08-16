import 'dart:math' as math;

import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/idle_beat_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Tells a first-time student that the steps can be swiped, then gets out of
/// the way.
///
/// It lives in a zero-height slot so it floats over the button dock rather
/// than pushing it down, and it never takes a tap — everything under it stays
/// reachable.
class SwipeHintMolecule extends StatefulWidget {
  /// How long the hint waits before retiring unprompted.
  static const Duration linger = Duration(milliseconds: 3400);

  /// How long it takes to fade once its time is up.
  static const Duration fade = Duration(milliseconds: 600);

  /// How quickly it leaves once the student has actually moved a step.
  static const Duration dismissed = Duration(milliseconds: 350);

  /// Set once the student has moved between steps by any means. The hint has
  /// been answered, so it should stop talking.
  final bool used;

  const SwipeHintMolecule({super.key, this.used = false});

  @override
  State<SwipeHintMolecule> createState() => _SwipeHintMoleculeState();
}

class _SwipeHintMoleculeState extends State<SwipeHintMolecule>
    with SingleTickerProviderStateMixin {
  late final AnimationController _out;

  /// The fraction of the timeline spent waiting before the fade begins.
  static const double _wait = 3400 / (3400 + 600);

  @override
  void initState() {
    super.initState();
    _out = AnimationController(
      vsync: this,
      duration: SwipeHintMolecule.linger + SwipeHintMolecule.fade,
    );
    if (widget.used) {
      _out.value = 1;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !MotionPolicy.of(context)) return;
        _out.forward();
      });
    }
  }

  @override
  void didUpdateWidget(SwipeHintMolecule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.used && !oldWidget.used) _dismiss();
  }

  void _dismiss() {
    if (!MotionPolicy.of(context)) {
      _out.value = 1;
      return;
    }
    // Skip straight to the fade and run it faster: the hint has been answered,
    // so lingering would be talking over the student.
    _out
      ..duration = SwipeHintMolecule.dismissed
      ..value = 0
      ..forward();
  }

  @override
  void dispose() {
    _out.dispose();
    super.dispose();
  }

  double get _opacity {
    final v = _out.value;
    // While dismissed the whole timeline is the fade; otherwise the fade only
    // starts once the hint has had its say.
    final fading = _out.duration == SwipeHintMolecule.dismissed
        ? v
        : ((v - _wait) / (1 - _wait)).clamp(0.0, 1.0);
    return 1 - fading;
  }

  @override
  Widget build(BuildContext context) {
    if (!MotionPolicy.of(context)) return const SizedBox.shrink();

    return SizedBox(
      height: 0,
      child: OverflowBox(
        maxHeight: 40.h,
        alignment: Alignment.bottomCenter,
        child: IgnorePointer(
          child: Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: AnimatedBuilder(
              animation: _out,
              builder: (context, child) {
                final o = _opacity;
                if (o == 0) return const SizedBox.shrink();
                return FadeTransition(
                  opacity: AlwaysStoppedAnimation<double>(o),
                  child: child,
                );
              },
              child: _pill(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill() {
    return Container(
      key: const Key('swipe_hint'),
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: QuestPalette.glowBottom.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Swipe',
            style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w600,
              color: QuestPalette.body,
              height: 1.1,
            ),
          ),
          SizedBox(width: 3.w),
          Text(
            'between steps',
            style: TextStyle(
              fontSize: 10.5.sp,
              color: QuestPalette.dim,
              height: 1.1,
            ),
          ),
          SizedBox(width: 6.w),
          _nudge(),
        ],
      ),
    );
  }

  Widget _nudge() {
    return IdleBeatAtom(
      period: const Duration(milliseconds: 1500),
      beats: 3,
      child: Icon(
        Icons.chevron_right_rounded,
        key: const Key('swipe_hint_chevron'),
        size: 11.sp,
        color: QuestPalette.dim,
      ),
      builder: (context, phase, child) {
        // Out and back, the shape of the gesture it is asking for.
        final push = (1 - math.cos(phase * 2 * math.pi)) / 2;
        return Transform.translate(offset: Offset(5 * push, 0), child: child);
      },
    );
  }
}
