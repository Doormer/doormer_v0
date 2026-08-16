part of 'ask_by_photo_bloc.dart';

abstract class AskByPhotoState extends Equatable {
  const AskByPhotoState();

  @override
  List<Object?> get props => [];
}

class AskByPhotoInitial extends AskByPhotoState {
  const AskByPhotoInitial();
}

class AskByPhotoPhotoSelected extends AskByPhotoState {
  final Uint8List imageBytes;
  final String fileName;
  final String? mimeType;

  const AskByPhotoPhotoSelected({
    required this.imageBytes,
    required this.fileName,
    this.mimeType,
  });

  @override
  List<Object?> get props => [imageBytes, fileName, mimeType];
}

class AskByPhotoLoading extends AskByPhotoState {
  /// The photo being solved, carried through so the preview stays on screen for
  /// the whole in-flight solve instead of collapsing to the empty placeholder.
  /// Null only when a submit is dispatched with nothing selected.
  final Uint8List? imageBytes;
  final String? fileName;

  const AskByPhotoLoading({this.imageBytes, this.fileName});

  @override
  List<Object?> get props => [imageBytes, fileName];
}

class AskByPhotoSolved extends AskByPhotoState {
  final String questionId;
  final SolutionDocument solution;

  const AskByPhotoSolved({
    required this.questionId,
    required this.solution,
  });

  @override
  List<Object?> get props => [questionId, solution];
}

class AskByPhotoUnreadable extends AskByPhotoState {
  final String questionId;

  const AskByPhotoUnreadable({required this.questionId});

  @override
  List<Object?> get props => [questionId];
}

class AskByPhotoNotAQuestion extends AskByPhotoState {
  final String questionId;

  const AskByPhotoNotAQuestion({required this.questionId});

  @override
  List<Object?> get props => [questionId];
}

class AskByPhotoTimeout extends AskByPhotoState {
  final String questionId;

  const AskByPhotoTimeout({required this.questionId});

  @override
  List<Object?> get props => [questionId];
}

class AskByPhotoValidationError extends AskByPhotoState {
  final String message;

  const AskByPhotoValidationError(this.message);

  @override
  List<Object?> get props => [message];
}

class AskByPhotoNetworkError extends AskByPhotoState {
  final String message;

  const AskByPhotoNetworkError(this.message);

  @override
  List<Object?> get props => [message];
}

class AskByPhotoNotice extends AskByPhotoState {
  final String message;

  const AskByPhotoNotice(this.message);

  @override
  List<Object?> get props => [message];
}

class AskByPhotoTypeInstead extends AskByPhotoState {
  const AskByPhotoTypeInstead();
}
