/// What Solve says about today's questions.
class DailyLimitParams {
  /// "3 questions left today" or, with none left, when they come back.
  final String text;

  /// None left today: nothing can be picked or sent.
  final bool isReached;

  const DailyLimitParams({required this.text, required this.isReached});
}
