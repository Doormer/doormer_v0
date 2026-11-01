import 'package:doormer/src/features/questions/domain/entity/daily_limit.dart';

/// The API's `daily_limit`:
/// `{"questions_left": 3, "resets_at": "2026-10-19T00:00:00+13:00"}`.
class DailyLimitModel {
  final int questionsLeft;
  final DateTime resetsAt;

  const DailyLimitModel({required this.questionsLeft, required this.resetsAt});

  /// Throws a [FormatException] when either field is missing or unreadable.
  factory DailyLimitModel.fromJson(Map<String, dynamic> json) {
    final questionsLeft = json['questions_left'];
    final resetsAtJson = json['resets_at'];
    final resetsAt =
        resetsAtJson is String ? DateTime.tryParse(resetsAtJson) : null;
    if (questionsLeft is! num || resetsAt == null) {
      throw const FormatException(
          'daily_limit needs questions_left and resets_at');
    }
    return DailyLimitModel(
      questionsLeft: questionsLeft < 0 ? 0 : questionsLeft.toInt(),
      resetsAt: resetsAt,
    );
  }

  DailyLimit toEntity() =>
      DailyLimit(questionsLeft: questionsLeft, resetsAt: resetsAt);
}
