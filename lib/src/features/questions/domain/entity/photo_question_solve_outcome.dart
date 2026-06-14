enum PhotoQuestionSolveStatus {
  solved,
  unreadable,
  notAQuestion,
  timeout,
}

class PhotoQuestionSolveOutcome {
  final PhotoQuestionSolveStatus status;
  final String questionId;
  final SolutionDocument? solution;

  const PhotoQuestionSolveOutcome({
    required this.status,
    required this.questionId,
    required this.solution,
  });
}

class SolutionDocument {
  final String schemaVersion;
  final List<SolutionStep> steps;
  final FinalAnswer finalAnswer;

  const SolutionDocument({
    required this.schemaVersion,
    required this.steps,
    required this.finalAnswer,
  });
}

class SolutionStep {
  final String title;
  final List<SolutionSegment> body;

  const SolutionStep({
    required this.title,
    required this.body,
  });
}

abstract class SolutionSegment {
  const SolutionSegment();
}

class TextSolutionSegment extends SolutionSegment {
  final String value;

  const TextSolutionSegment(this.value);
}

class MathSolutionSegment extends SolutionSegment {
  final String latex;
  final String alt;

  const MathSolutionSegment({
    required this.latex,
    required this.alt,
  });
}

class FinalAnswer {
  final List<SolutionSegment> body;

  const FinalAnswer({required this.body});
}
