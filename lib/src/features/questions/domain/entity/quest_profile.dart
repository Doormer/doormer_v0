/// The student's standing as the solution reader shows it: banked XP, the
/// study streak, and where this question sits in the syllabus.
///
/// No endpoint serves this yet, so it is mocked at the datasource. Everything
/// above the datasource already treats it as real data, so switching to the
/// API is a one-file change.
class QuestProfile {
  /// XP banked before this question was opened. Reading steps adds to it.
  final int bankedXp;

  final int streakDays;

  /// Syllabus crumb, e.g. `Geometry - Area`.
  final String topic;

  /// The question's own name, e.g. `Road through a field`.
  final String questionTitle;

  const QuestProfile({
    required this.bankedXp,
    required this.streakDays,
    required this.topic,
    required this.questionTitle,
  });
}
