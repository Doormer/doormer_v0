import 'package:flutter/material.dart';

/// One switch for every animation in the app.
///
/// The design disables all motion under `prefers-reduced-motion`, which Flutter
/// surfaces as [MediaQueryData.disableAnimations]. Routing every animation
/// through here means a user who asked for stillness gets it everywhere, rather
/// than everywhere someone remembered to check.
///
/// The rule that matters most is [settled]. An entrance animation that fades or
/// slides content in must, when motion is off, leave that content **visible and
/// in place** — never stuck at its start value. Disabling motion must cost the
/// user movement, never information. The prototype spells this out by resetting
/// `.anim>*` to `opacity:1;transform:none` inside its reduced-motion block.
abstract final class MotionPolicy {
  /// Whether animation should run at all.
  ///
  /// Absent a [MediaQuery] the answer is yes: motion is the default, and only
  /// an explicit request for stillness turns it off.
  static bool of(BuildContext context) {
    return !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
  }

  /// [full], or [Duration.zero] when motion is off.
  ///
  /// A zero duration still lets an implicit animation *arrive* at its target,
  /// which is what keeps content visible instead of frozen mid-transition.
  static Duration duration(BuildContext context, Duration full) {
    return of(context) ? full : Duration.zero;
  }

  /// The value an entrance animation should sit at when motion is off: fully
  /// arrived, so nothing is hidden.
  static double settled(BuildContext context, double animating) {
    return of(context) ? animating : 1.0;
  }

  /// Whether a looping idle animation — a bob, a pulse, a wiggle — should run.
  ///
  /// Separated from [of] because looping decoration is the first thing to drop:
  /// it never conveys state, so switching it off costs nothing at all.
  static bool idle(BuildContext context) => of(context);
}
