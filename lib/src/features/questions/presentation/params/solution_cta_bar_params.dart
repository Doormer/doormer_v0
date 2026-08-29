import 'package:flutter/widgets.dart';

/// Plain holder — deliberately not Equatable, because it carries callbacks
/// which compare by reference.
class SolutionCtaBarParams {
  final String ctaLabel;

  /// Whether the button should read as finished.
  final bool ctaSolved;

  /// Already resolved above this layer: the bar does not work out what the
  /// button means, it only presses it. Never null — the reader's button is
  /// always live, and only its destination changes.
  final VoidCallback onCtaPressed;

  final bool canGoBack;
  final VoidCallback onBack;

  /// Whether to float the swipe hint above the dock. Hidden on the briefing,
  /// where there is nothing behind the student to swipe back to.
  final bool showSwipeHint;

  /// Whether the student has already swiped, which is what retires the hint.
  final bool swipeHintUsed;

  const SolutionCtaBarParams({
    required this.ctaLabel,
    required this.ctaSolved,
    required this.onCtaPressed,
    required this.canGoBack,
    required this.onBack,
    required this.showSwipeHint,
    required this.swipeHintUsed,
  });
}
