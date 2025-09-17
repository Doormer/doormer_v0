class Question {
  final String id;
  final String questionText;
  final String? imageUrl;
  final String questionType;
  final List<String> stepByStepSolution;
  final String answer;
  final String difficulty;
  final List<String> tags;

  Question({
    required this.id,
    required this.questionText,
    this.imageUrl,
    required this.questionType,
    required this.stepByStepSolution,
    required this.answer,
    required this.difficulty,
    required this.tags,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Question && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
