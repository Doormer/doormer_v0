/// What Solve says about today's questions.
class DailyLimitParams {
  /// "3 questions left today" or, with none left, when they come back.
  final String text;

  /// None left today: no photo can be picked or edited, and the only photo
  /// that can still be sent is one the API may hold an answer for, which it
  /// gives back whatever the limit.
  final bool isReached;

  const DailyLimitParams({required this.text, required this.isReached});
}
