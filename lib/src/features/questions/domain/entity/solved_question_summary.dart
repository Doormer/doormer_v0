import 'package:equatable/equatable.dart';

/// One solved question as the Saved list shows it.
class SolvedQuestionSummary extends Equatable {
  final String questionId;

  /// A broad area and the topic, such as "Geometry - Area". Empty when the
  /// solver named none.
  final String topic;

  /// The rule the solution relies on, such as "Pythagoras' theorem". Empty
  /// when the solver named none.
  final String method;

  /// The question text read from the photo. Empty when the photo had none.
  final String questionText;

  final DateTime askedAt;

  /// A small copy of the student's photo. Null when there is none.
  final String? thumbnailUrl;

  /// The full photo. Null when its link could not be made.
  final String? photoUrl;

  const SolvedQuestionSummary({
    required this.questionId,
    required this.topic,
    required this.method,
    required this.questionText,
    required this.askedAt,
    this.thumbnailUrl,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [
        questionId,
        topic,
        method,
        questionText,
        askedAt,
        thumbnailUrl,
        photoUrl,
      ];
}
