part of 'mistake_mirror_bloc.dart';

abstract class MistakeMirrorEvent extends Equatable {
  const MistakeMirrorEvent();

  @override
  List<Object?> get props => [];
}

class AnalyzeQuestionEvent extends MistakeMirrorEvent {
  final Uint8List imageBytes;
  final String fileName;

  const AnalyzeQuestionEvent({
    required this.imageBytes,
    required this.fileName,
  });

  @override
  List<Object?> get props => [imageBytes, fileName];
}

class GetQuestionDetailsEvent extends MistakeMirrorEvent {
  final String questionId;

  const GetQuestionDetailsEvent({required this.questionId});

  @override
  List<Object?> get props => [questionId];
}

class RecordInteractionEvent extends MistakeMirrorEvent {
  final String questionId;
  final String interactionType;
  final Map<String, dynamic>? metadata;

  const RecordInteractionEvent({
    required this.questionId,
    required this.interactionType,
    this.metadata,
  });

  @override
  List<Object?> get props => [questionId, interactionType, metadata];
}

class LoadHistoryEvent extends MistakeMirrorEvent {
  const LoadHistoryEvent();
}

class BookmarkQuestionEvent extends MistakeMirrorEvent {
  final String questionId;
  final bool isBookmarked;

  const BookmarkQuestionEvent({
    required this.questionId,
    required this.isBookmarked,
  });

  @override
  List<Object?> get props => [questionId, isBookmarked];
}

class LoadBookmarksEvent extends MistakeMirrorEvent {
  const LoadBookmarksEvent();
}

class ClearAnalysisEvent extends MistakeMirrorEvent {
  const ClearAnalysisEvent();
}

class SelectQuestionEvent extends MistakeMirrorEvent {
  final Question question;

  const SelectQuestionEvent({required this.question});

  @override
  List<Object?> get props => [question];
}
