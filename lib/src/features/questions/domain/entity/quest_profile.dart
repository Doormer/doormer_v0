/// The student's standing as the solution reader shows it: the study streak,
/// and where this question sits in the syllabus.
///
/// No endpoint serves this yet, so it is mocked at the datasource. Quarks come
/// from their own endpoints and do not belong in this profile.
class QuestProfile {
  final int streakDays;

  /// Syllabus crumb, e.g. `Geometry - Area`.
  final String topic;

  /// The question's own name, e.g. `Road through a field`.
  final String questionTitle;

  const QuestProfile({
    required this.streakDays,
    required this.topic,
    required this.questionTitle,
  });
}
