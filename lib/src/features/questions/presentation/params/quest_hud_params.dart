/// Plain holder for the standing bar. Carries no callbacks today, but stays a
/// params object so the HUD's signature does not change when it gains one.
class QuestHudParams {
  final String topic;
  final String questionTitle;

  /// Empty while the standing has not loaded — the pill is then absent rather
  /// than showing a zero it is about to replace.
  final String xpLabel;
  final String streakLabel;

  const QuestHudParams({
    required this.topic,
    required this.questionTitle,
    required this.xpLabel,
    required this.streakLabel,
  });
}
