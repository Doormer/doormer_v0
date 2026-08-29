import 'package:flutter/widgets.dart';

/// The four things a trail node can be.
///
/// [ready] exists only for the vault: amber means "you can open this now",
/// which is a different promise from [current] ("you are reading this"). Using
/// pink for both would tell the student they are in two places at once.
enum SolutionTrailNodeState { done, current, upcoming, ready }

/// Round nodes are steps you read. Square nodes are the two destinations that
/// bookend the trail, so both ends look like places rather than stops.
enum SolutionTrailNodeShape { step, marker }

class SolutionTrailNode {
  /// The briefing sits ahead of step 0, so it numbers one behind it.
  static const int briefingPosition = -1;

  final int displayNumber;
  final SolutionTrailNodeState state;
  final String semanticsLabel;

  /// Drawn instead of [displayNumber] on a node that is not a numbered step,
  /// such as the briefing at the head of the trail. Step nodes leave this null
  /// so their numbering never shifts.
  final IconData? icon;

  final SolutionTrailNodeShape shape;

  /// The trail position tapping this node returns the student to:
  /// [briefingPosition] for the briefing at the head, otherwise a zero-based
  /// step index.
  ///
  /// Null on any node that is not a place they can go — the road ahead, and
  /// the vault, which is a destination rather than a stop.
  final int? travelTo;

  /// How many of the three chains strapped across this node have already been
  /// broken. Null on every node that is not the vault — the briefing marker
  /// was never locked, so it was never chained.
  final int? chainsBroken;

  /// Whether this node should ring a few times to say it can be returned to.
  /// The plan at the head of the trail is the one thing students never think
  /// to go back to, so it is the one thing that asks.
  final bool invites;

  const SolutionTrailNode({
    required this.displayNumber,
    required this.state,
    required this.semanticsLabel,
    this.icon,
    this.shape = SolutionTrailNodeShape.step,
    this.travelTo,
    this.chainsBroken,
    this.invites = false,
  });
}
