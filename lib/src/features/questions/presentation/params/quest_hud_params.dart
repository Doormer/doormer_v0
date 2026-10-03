import 'package:flutter/widgets.dart';

/// Parameters for the bar at the top of the reader.
class QuestHudParams {
  final String topic;
  final String method;

  /// Empty while the balance has not loaded — the pill is then absent rather
  /// than showing a zero it is about to replace.
  final String quarkBalanceLabel;

  /// Locates the quark dot so a reward chip can be aimed at it.
  final Key? quarkKey;

  /// Changes when quarks land, so the pill can react to being paid.
  final Object? quarkTrigger;

  const QuestHudParams({
    required this.topic,
    required this.method,
    required this.quarkBalanceLabel,
    this.quarkKey,
    this.quarkTrigger,
  });
}
