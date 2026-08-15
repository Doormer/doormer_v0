import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';

class PhotoQuestionResponseModel {
  final PhotoQuestionSolveStatus status;
  final String questionId;
  final SolutionDocumentModel? solution;
  final String note;

  const PhotoQuestionResponseModel({
    required this.status,
    required this.questionId,
    required this.solution,
    this.note = '',
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
      note: json['note']?.toString() ?? '',
    );
  }

  PhotoQuestionSolveOutcome toEntity() {
    return PhotoQuestionSolveOutcome(
      status: status,
      questionId: questionId,
      solution: solution?.toEntity(),
      note: note,
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
  final SolutionSectionModel approach;
  final SolutionSectionModel verification;

  const SolutionDocumentModel({
    required this.schemaVersion,
    required this.steps,
    required this.finalAnswer,
    this.approach = const SolutionSectionModel(body: []),
    this.verification = const SolutionSectionModel(body: []),
  });

  factory SolutionDocumentModel.fromJson(Map<String, dynamic> json) {
    final stepsJson = json['steps'];
    final finalAnswerJson = json['final_answer'];

    if (finalAnswerJson is! Map<String, dynamic>) {
      throw const FormatException('Solution document missing final_answer');
    }

    final steps = stepsJson is List
        ? stepsJson
            .whereType<Map<String, dynamic>>()
            .map(SolutionStepModel.fromJson)
            .toList(growable: false)
        : const <SolutionStepModel>[];

    if (steps.isEmpty) {
      throw const FormatException('Solution document has no steps');
    }

    return SolutionDocumentModel(
      schemaVersion: json['schema_version']?.toString() ?? '',
      steps: steps,
      finalAnswer: FinalAnswerModel.fromJson(finalAnswerJson),
      approach: SolutionSectionModel.fromJson(json['approach']),
      verification: SolutionSectionModel.fromJson(json['verification']),
    );
  }

  SolutionDocument toEntity() {
    return SolutionDocument(
      schemaVersion: schemaVersion,
      steps: steps.map((step) => step.toEntity()).toList(growable: false),
      finalAnswer: finalAnswer.toEntity(),
      approach: approach.toEntity(),
      verification: verification.toEntity(),
    );
  }
}

class SolutionSectionModel {
  final List<SolutionSegmentModel> body;

  const SolutionSectionModel({required this.body});

  factory SolutionSectionModel.fromJson(dynamic json) {
    return SolutionSectionModel(
      body: json is Map<String, dynamic> ? _parseBody(json['body']) : const [],
    );
  }

  SolutionSection toEntity() {
    return SolutionSection(
      body: body.map((segment) => segment.toEntity()).toList(growable: false),
    );
  }
}

class SolutionStepModel {
  final String title;
  final List<SolutionSegmentModel> body;
  final List<SolutionSegmentModel> rationale;

  const SolutionStepModel({
    required this.title,
    required this.body,
    this.rationale = const [],
  });

  factory SolutionStepModel.fromJson(Map<String, dynamic> json) {
    return SolutionStepModel(
      title: json['title']?.toString() ?? '',
      body: _parseBody(json['body']),
      rationale: _parseBody(json['rationale']),
    );
  }

  SolutionStep toEntity() {
    return SolutionStep(
      title: title,
      body: body.map((segment) => segment.toEntity()).toList(growable: false),
      rationale:
          rationale.map((segment) => segment.toEntity()).toList(growable: false),
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

  /// Returns `null` for segment types this build does not know about, so a
  /// forward-compatible payload degrades to a missing block, not a dead page.
  static SolutionSegmentModel? tryParse(Map<String, dynamic> json) {
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
      case 'visual':
        return VisualSolutionSegmentModel(
          mediaType: json['media_type']?.toString() ?? '',
          url: json['url']?.toString() ?? '',
          width: _parseDimension(json['width']),
          height: _parseDimension(json['height']),
          caption: json['caption']?.toString() ?? '',
          alt: json['alt']?.toString() ?? '',
        );
      default:
        return null;
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

class VisualSolutionSegmentModel extends SolutionSegmentModel {
  final String mediaType;
  final String url;
  final int width;
  final int height;
  final String caption;
  final String alt;

  const VisualSolutionSegmentModel({
    required this.mediaType,
    required this.url,
    required this.width,
    required this.height,
    required this.caption,
    required this.alt,
  });

  @override
  VisualSolutionSegment toEntity() => VisualSolutionSegment(
        mediaType: mediaType,
        url: url,
        width: width,
        height: height,
        caption: caption,
        alt: alt,
      );
}

int _parseDimension(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<SolutionSegmentModel> _parseBody(dynamic bodyJson) {
  if (bodyJson is! List) {
    return const [];
  }

  return bodyJson
      .whereType<Map<String, dynamic>>()
      .map(SolutionSegmentModel.tryParse)
      .whereType<SolutionSegmentModel>()
      .toList(growable: false);
}
