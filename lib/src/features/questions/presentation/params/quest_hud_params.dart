import 'package:flutter/widgets.dart';

/// Plain holder for the standing bar. Carries no callbacks today, but stays a
/// params object so the HUD's signature does not change when it gains one.
class QuestHudParams {
  final String topic;
  final String questionTitle;

  /// Empty while the balance has not loaded — the pill is then absent rather
  /// than showing a zero it is about to replace.
  final String quarkBalanceLabel;
  final String streakLabel;

  /// Marks the streak as losable right now, so the pill can say so once.
  final bool streakAtStake;

  /// Locates the quark dot so a reward chip can be aimed at it.
  final Key? quarkKey;

  /// Changes when quarks land, so the pill can react to being paid.
  final Object? quarkTrigger;

  const QuestHudParams({
    required this.topic,
    required this.questionTitle,
    required this.quarkBalanceLabel,
    required this.streakLabel,
    this.streakAtStake = false,
    this.quarkKey,
    this.quarkTrigger,
  });
}
