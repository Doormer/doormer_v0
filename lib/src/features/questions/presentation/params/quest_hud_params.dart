import 'package:flutter/widgets.dart';

/// Plain holder for the standing bar. Carries no callbacks today, but stays a
/// params object so the HUD's signature does not change when it gains one.
class QuestHudParams {
  final String topic;
  final String questionTitle;

  /// Empty while the standing has not loaded — the pill is then absent rather
  /// than showing a zero it is about to replace.
  final String xpLabel;
  final String streakLabel;

  /// Locates the XP pill so a pellet can be aimed at it.
  final Key? xpKey;

  /// Changes when XP lands, so the pill can react to being paid.
  final Object? xpTrigger;

  const QuestHudParams({
    required this.topic,
    required this.questionTitle,
    required this.xpLabel,
    required this.streakLabel,
    this.xpKey,
    this.xpTrigger,
  });
}
