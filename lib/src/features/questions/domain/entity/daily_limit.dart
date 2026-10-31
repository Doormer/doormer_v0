/// How many questions the student can still ask today, and when they come
/// back. The API keeps the count and enforces it; the app only shows it.
class DailyLimit {
  /// Never below 0. At 0 nothing can be asked until [resetsAt].
  final int questionsLeft;

  /// When today's questions come back. Show it in the student's own zone with
  /// [DateTime.toLocal].
  final DateTime resetsAt;

  const DailyLimit({required this.questionsLeft, required this.resetsAt});

  bool get isReached => questionsLeft <= 0;

  @override
  bool operator ==(Object other) =>
      other is DailyLimit &&
      other.questionsLeft == questionsLeft &&
      other.resetsAt.isAtSameMomentAs(resetsAt);

  @override
  int get hashCode =>
      Object.hash(questionsLeft, resetsAt.microsecondsSinceEpoch);
}
