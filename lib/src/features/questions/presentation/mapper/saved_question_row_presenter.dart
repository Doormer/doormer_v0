import 'package:doormer/src/features/questions/domain/entity/solved_question_summary.dart';

/// The words one row of the Saved list shows for a question.
class SavedQuestionRowContent {
  /// The topic, such as "Geometry · Area".
  final String title;

  /// The first line of the question text, or the method when the photo had
  /// no text. Empty when there is neither.
  final String detail;

  /// When the question was asked, such as "Today" or "3 Oct".
  final String askedLabel;

  const SavedQuestionRowContent({
    required this.title,
    required this.detail,
    required this.askedLabel,
  });
}

/// What the row for [question] says, with its time measured against [now].
SavedQuestionRowContent savedQuestionRowContent(
  SolvedQuestionSummary question, {
  required DateTime now,
}) {
  return SavedQuestionRowContent(
    title: savedQuestionTitle(question.topic),
    detail: savedQuestionDetail(
      questionText: question.questionText,
      method: question.method,
    ),
    askedLabel: askedLabel(question.askedAt, now: now),
  );
}

/// The solver writes a topic as "Area - Topic". The row shows "Area · Topic",
/// which reads as a place rather than a subtraction.
String savedQuestionTitle(String topic) {
  final trimmed = topic.trim();
  if (trimmed.isEmpty) return 'Question';
  return trimmed.replaceAll(' - ', ' · ');
}

/// The first non-blank line of the question text. A photo with no printed
/// text, such as a diagram, a graph or handwriting, falls back to the method.
String savedQuestionDetail({
  required String questionText,
  required String method,
}) {
  for (final line in questionText.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return method.trim();
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// When a question was asked, in the device's time zone: "Today",
/// "Yesterday", the weekday within the last week, then the day and month,
/// with the year added once it is an earlier year.
String askedLabel(DateTime askedAt, {required DateTime now}) {
  final asked = askedAt.toLocal();
  final today = now.toLocal();
  // Whole calendar days, counted on UTC midnights so a daylight-saving change
  // cannot shorten a day to 23 hours.
  final daysAgo = DateTime.utc(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime.utc(asked.year, asked.month, asked.day)).inDays;
  if (daysAgo <= 0) return 'Today';
  if (daysAgo == 1) return 'Yesterday';
  if (daysAgo < 7) return _weekdays[asked.weekday - 1];
  final dayAndMonth = '${asked.day} ${_months[asked.month - 1]}';
  return asked.year == today.year ? dayAndMonth : '$dayAndMonth ${asked.year}';
}
