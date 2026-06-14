import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';

class PhotoQuestionResponseModel {
  final PhotoQuestionSolveStatus status;
  final String questionId;
  final SolutionDocumentModel? solution;

  const PhotoQuestionResponseModel({
    required this.status,
    required this.questionId,
    required this.solution,
  });

  factory PhotoQuestionResponseModel.fromJson(Map<String, dynamic> json) {
    final status = _parseStatus(json['status']?.toString());
    final solutionJson = json['solution'];
    final solution = solutionJson is Map<String, dynamic>
        ? SolutionDocumentModel.fromJson(solutionJson)
        : null;

    if (status == PhotoQuestionSolveStatus.solved && solution == null) {
      throw const FormatException('Solved photo response missing solution');
    }

    return PhotoQuestionResponseModel(
      status: status,
      questionId: json['question_id']?.toString() ?? '',
      solution: solution,
    );
  }

  PhotoQuestionSolveOutcome toEntity() {
    return PhotoQuestionSolveOutcome(
      status: status,
      questionId: questionId,
      solution: solution?.toEntity(),
    );
  }

  static PhotoQuestionSolveStatus _parseStatus(String? status) {
    switch (status) {
      case 'solved':
        return PhotoQuestionSolveStatus.solved;
      case 'unreadable':
        return PhotoQuestionSolveStatus.unreadable;
      case 'not_a_question':
        return PhotoQuestionSolveStatus.notAQuestion;
      case 'timeout':
        return PhotoQuestionSolveStatus.timeout;
      default:
        throw FormatException('Unknown photo question status: $status');
    }
  }
}

class SolutionDocumentModel {
  final String schemaVersion;
  final List<SolutionStepModel> steps;
  final FinalAnswerModel finalAnswer;

  const SolutionDocumentModel({
    required this.schemaVersion,
    required this.steps,
    required this.finalAnswer,
  });

  factory SolutionDocumentModel.fromJson(Map<String, dynamic> json) {
    final stepsJson = json['steps'];
    final finalAnswerJson = json['final_answer'];

    if (finalAnswerJson is! Map<String, dynamic>) {
      throw const FormatException('Solution document missing final_answer');
    }

    return SolutionDocumentModel(
      schemaVersion: json['schema_version']?.toString() ?? '',
      steps: stepsJson is List
          ? stepsJson
              .whereType<Map<String, dynamic>>()
              .map(SolutionStepModel.fromJson)
              .toList(growable: false)
          : const [],
      finalAnswer: FinalAnswerModel.fromJson(finalAnswerJson),
    );
  }

  SolutionDocument toEntity() {
    return SolutionDocument(
      schemaVersion: schemaVersion,
      steps: steps.map((step) => step.toEntity()).toList(growable: false),
      finalAnswer: finalAnswer.toEntity(),
    );
  }
}

class SolutionStepModel {
  final String title;
  final List<SolutionSegmentModel> body;

  const SolutionStepModel({
    required this.title,
    required this.body,
  });

  factory SolutionStepModel.fromJson(Map<String, dynamic> json) {
    return SolutionStepModel(
      title: json['title']?.toString() ?? '',
      body: _parseBody(json['body']),
    );
  }

  SolutionStep toEntity() {
    return SolutionStep(
      title: title,
      body: body.map((segment) => segment.toEntity()).toList(growable: false),
    );
  }
}

class FinalAnswerModel {
  final List<SolutionSegmentModel> body;

  const FinalAnswerModel({required this.body});

  factory FinalAnswerModel.fromJson(Map<String, dynamic> json) {
    return FinalAnswerModel(body: _parseBody(json['body']));
  }

  FinalAnswer toEntity() {
    return FinalAnswer(
      body: body.map((segment) => segment.toEntity()).toList(growable: false),
    );
  }
}

abstract class SolutionSegmentModel {
  const SolutionSegmentModel();

  factory SolutionSegmentModel.fromJson(Map<String, dynamic> json) {
    switch (json['type']?.toString()) {
      case 'text':
        return TextSolutionSegmentModel(
          value: json['value']?.toString() ?? '',
        );
      case 'math':
        return MathSolutionSegmentModel(
          latex: json['latex']?.toString() ?? '',
          alt: json['alt']?.toString() ?? '',
        );
      default:
        throw FormatException('Unknown solution segment type: ${json['type']}');
    }
  }

  SolutionSegment toEntity();
}

class TextSolutionSegmentModel extends SolutionSegmentModel {
  final String value;

  const TextSolutionSegmentModel({required this.value});

  @override
  TextSolutionSegment toEntity() => TextSolutionSegment(value);
}

class MathSolutionSegmentModel extends SolutionSegmentModel {
  final String latex;
  final String alt;

  const MathSolutionSegmentModel({
    required this.latex,
    required this.alt,
  });

  @override
  MathSolutionSegment toEntity() => MathSolutionSegment(latex: latex, alt: alt);
}

List<SolutionSegmentModel> _parseBody(dynamic bodyJson) {
  if (bodyJson is! List) {
    return const [];
  }

  return bodyJson
      .whereType<Map<String, dynamic>>()
      .map(SolutionSegmentModel.fromJson)
      .toList(growable: false);
}
