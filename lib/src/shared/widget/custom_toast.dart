import 'dart:async';
import 'dart:math' as math;

import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/shared/design/atomic/atoms/toast_atom.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// Shows a short message over every page, in the app's own toast
/// ([ToastAtom]). The whole app shows its toasts through here.
class CustomToast {
  /// The least room a toast leaves between itself and either side of the
  /// screen.
  static const double _minSideGap = 16;

  /// The room between toasts that show at the same time.
  static const double _gap = 8;

  /// How far a toast travels as it arrives and as it leaves.
  static const double _travel = 12;

  static const Duration _arrival = Duration(milliseconds: 220);
  static const Duration _departure = Duration(milliseconds: 160);

  /// Shows [message] at [alignment], the top centre unless told otherwise,
  /// so it never covers the nav bar or a page's buttons along the bottom.
  ///
  /// It stays for [autoCloseDuration], which defaults to
  /// [defaultDurationFor] its [type]. A tap closes it sooner, and so does a
  /// swipe toward the edge it sits on.
  ///
  /// It is as wide as its message needs, up to the 400 logical pixels
  /// toastification lays its toasts out in, and keeps 16 logical pixels from
  /// the sides of the screen.
  static void show(
    BuildContext context, {
    required String message,
    required ToastificationType type,
    Alignment alignment = Alignment.topCenter,
    Duration? autoCloseDuration,
  }) {
    final shownFor = autoCloseDuration ?? defaultDurationFor(type);
    toastification.showCustom(
      context: context,
      alignment: alignment,
      // The toast moves itself in and out. toastification would also grow
      // the toast's slot open from its middle, which slides the toast even
      // when animations are off.
      animationDuration: Duration.zero,
      animationBuilder: (_, __, ___, child) => child,
      // Only a backstop, a little after the toast should have faded out on
      // its own.
      autoCloseDuration: shownFor + _departure * 3,
      builder: (_, item) => _ShownToast(
        // toastification's list matches toasts to its slots by position, so
        // a toast changes slot whenever another arrives above it or leaves.
        // Its own global key moves it to the new slot. Built afresh instead,
        // it would arrive again, restart its time and be announced again.
        key: GlobalObjectKey(item),
        shownFor: shownFor,
        fromBelow: alignment.y > 0,
        onGone: () => toastification.dismiss(item, showRemoveAnimation: false),
        child: ToastAtom(message: message, kind: _kindOf(type)),
      ),
    );
  }

  static Duration defaultDurationFor(ToastificationType type) =>
      type == ToastificationType.error
          ? const Duration(seconds: 4)
          : const Duration(seconds: 2);

  static ToastKind _kindOf(ToastificationType type) => switch (type) {
        ToastificationType.success => ToastKind.success,
        ToastificationType.error => ToastKind.error,
        ToastificationType.warning => ToastKind.warning,
        _ => ToastKind.info,
      };
}

/// A toast while it shows. It fades in as it slides toward the middle of the
/// screen, stays for [shownFor], then leaves the way it came, sooner when
/// tapped or swiped toward its edge. [onGone] runs once it has faded out.
///
/// With animations off, it only fades.
class _ShownToast extends StatefulWidget {
  final Duration shownFor;

  /// The toast sits at the bottom, so it rises into place and is swiped
  /// down to close. Otherwise it drops into place and is swiped up.
  final bool fromBelow;

  final VoidCallback onGone;
  final Widget child;

  const _ShownToast({
    super.key,
    required this.shownFor,
    required this.fromBelow,
    required this.onGone,
    required this.child,
  });

  @override
  State<_ShownToast> createState() => _ShownToastState();
}

class _ShownToastState extends State<_ShownToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _presence;
  late final CurvedAnimation _eased;
  late final Timer _timeUp;

  /// How far the student has dragged the toast toward its edge.
  double _dragged = 0;
  bool _leaving = false;

  /// Up the screen, or down it for a toast at the bottom.
  double get _towardEdge => widget.fromBelow ? 1 : -1;

  @override
  void initState() {
    super.initState();
    _presence = AnimationController(
      vsync: this,
      duration: CustomToast._arrival,
      reverseDuration: CustomToast._departure,
    )..forward();
    _eased = CurvedAnimation(
      parent: _presence,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _timeUp = Timer(widget.shownFor, _leave);
  }

  @override
  void dispose() {
    _timeUp.cancel();
    _eased.dispose();
    _presence.dispose();
    super.dispose();
  }

  void _leave() {
    if (_leaving) return;
    _leaving = true;
    _timeUp.cancel();
    _presence.reverse().then((_) => widget.onGone());
  }

  void _drag(DragUpdateDetails details) {
    final dragged = _dragged + details.delta.dy;
    setState(() {
      _dragged = widget.fromBelow ? math.max(0, dragged) : math.min(0, dragged);
    });
  }

  @override
  Widget build(BuildContext context) {
    final slides = MotionPolicy.of(context);
    final toast = GestureDetector(
      excludeFromSemantics: true,
      onTap: _leave,
      onVerticalDragUpdate: _drag,
      onVerticalDragEnd: (_) {
        if (_dragged != 0) _leave();
      },
      child: widget.child,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // toastification centres its column of toasts on the screen, so on
        // a phone the column is the screen's whole width.
        final columnGap =
            (MediaQuery.sizeOf(context).width - constraints.maxWidth) / 2;
        final sideGap = math.max(0.0, CustomToast._minSideGap - columnGap);
        return Padding(
          padding: EdgeInsets.fromLTRB(sideGap, 0, sideGap, CustomToast._gap),
          child: Align(
            alignment: Alignment.topCenter,
            child: FadeTransition(
              opacity: _eased,
              child: AnimatedBuilder(
                animation: _eased,
                builder: (context, child) {
                  final arriving = slides
                      ? _towardEdge * CustomToast._travel * (1 - _eased.value)
                      : 0.0;
                  return Transform.translate(
                    offset: Offset(0, _dragged + arriving),
                    child: child,
                  );
                },
                child: toast,
              ),
            ),
          ),
        );
      },
    );
  }
}
