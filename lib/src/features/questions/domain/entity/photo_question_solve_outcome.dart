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

  /// Free-form solver commentary. Present from schema 3.0 onwards.
  final String note;

  const PhotoQuestionSolveOutcome({
    required this.status,
    required this.questionId,
    required this.solution,
    this.note = '',
  });
}

class SolutionDocument {
  final String schemaVersion;
  final List<SolutionStep> steps;
  final FinalAnswer finalAnswer;
  final SolutionSection approach;
  final SolutionSection verification;

  const SolutionDocument({
    required this.schemaVersion,
    required this.steps,
    required this.finalAnswer,
    this.approach = const SolutionSection(body: []),
    this.verification = const SolutionSection(body: []),
  });
}

/// A titled-free block of segments such as `approach` or `verification`.
class SolutionSection {
  final List<SolutionSegment> body;

  const SolutionSection({required this.body});
}

class SolutionStep {
  final String title;
  final List<SolutionSegment> body;
  final List<SolutionSegment> rationale;

  const SolutionStep({
    required this.title,
    required this.body,
    this.rationale = const [],
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

class VisualSolutionSegment extends SolutionSegment {
  final String mediaType;
  final String url;
  final int width;
  final int height;
  final String caption;
  final String alt;

  const VisualSolutionSegment({
    required this.mediaType,
    required this.url,
    required this.width,
    required this.height,
    required this.caption,
    required this.alt,
  });

  /// Reserves layout before the remote image loads. 1.5 matches the payload's
  /// 1600x1067 renders and is the fallback when the server omits geometry.
  double get aspectRatio => height == 0 ? 1.5 : width / height;
}

class FinalAnswer {
  final List<SolutionSegment> body;

  const FinalAnswer({required this.body});
}
