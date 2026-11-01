import 'package:doormer/src/features/questions/domain/entity/shared_question_summary.dart';
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
    askedLabel: dayLabel(question.askedAt, now: now),
  );
}

/// The words one row of Shared with me shows for a question a friend shared.
class SharedQuestionRowContent {
  /// The topic, such as "Algebra · Linear equations".
  final String title;

  /// As a saved row's: the first line of the question text, or the method.
  final String detail;

  /// When the friend shared it, such as "Today" or "3 Oct".
  final String sharedLabel;

  const SharedQuestionRowContent({
    required this.title,
    required this.detail,
    required this.sharedLabel,
  });
}

/// What the row for [shared] says: the question as a saved row says it, but
/// when it was shared, measured against [now], rather than when it was asked.
/// Shared with me lists questions newest share first.
SharedQuestionRowContent sharedQuestionRowContent(
  SharedQuestionSummary shared, {
  required DateTime now,
}) {
  final question = shared.question;
  return SharedQuestionRowContent(
    title: savedQuestionTitle(question.topic),
    detail: savedQuestionDetail(
      questionText: question.questionText,
      method: question.method,
    ),
    sharedLabel: dayLabel(shared.sharedAt, now: now),
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

/// The day [time] fell on, such as when a question was asked or shared, in
/// the device's time zone: "Today", "Yesterday", the weekday within the last
/// week, then the day and month, with the year added once it is an earlier
/// year.
String dayLabel(DateTime time, {required DateTime now}) {
  final day = time.toLocal();
  final today = now.toLocal();
  // Whole calendar days, counted on UTC midnights so a daylight-saving change
  // cannot shorten a day to 23 hours.
  final daysAgo = DateTime.utc(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime.utc(day.year, day.month, day.day)).inDays;
  if (daysAgo <= 0) return 'Today';
  if (daysAgo == 1) return 'Yesterday';
  if (daysAgo < 7) return _weekdays[day.weekday - 1];
  final dayAndMonth = '${day.day} ${_months[day.month - 1]}';
  return day.year == today.year ? dayAndMonth : '$dayAndMonth ${day.year}';
}
