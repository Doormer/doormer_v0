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

/// A solve that ended without a solution, holding on to the photo that
/// produced it.
///
/// The bytes are kept so the preview stays on screen: a failure should cost a
/// tap, not force the student to find and pick the same file over again.
abstract class AskByPhotoSolveFailed extends AskByPhotoState {
  final Uint8List? imageBytes;
  final String? fileName;
  final String? mimeType;

  const AskByPhotoSolveFailed({
    this.imageBytes,
    this.fileName,
    this.mimeType,
  });

  /// Whether resubmitting these exact bytes could plausibly succeed.
  ///
  /// A blurry photo reads as blurry every time, so offering "Try again" there
  /// only wastes a round trip; a dropped connection is worth another go.
  bool get isRetryable;

  bool get hasPhoto => imageBytes != null;
}

class AskByPhotoUnreadable extends AskByPhotoSolveFailed {
  final String questionId;

  const AskByPhotoUnreadable({
    required this.questionId,
    super.imageBytes,
    super.fileName,
    super.mimeType,
  });

  @override
  bool get isRetryable => false;

  @override
  List<Object?> get props => [questionId, imageBytes, fileName, mimeType];
}

class AskByPhotoNotAQuestion extends AskByPhotoSolveFailed {
  final String questionId;

  const AskByPhotoNotAQuestion({
    required this.questionId,
    super.imageBytes,
    super.fileName,
    super.mimeType,
  });

  @override
  bool get isRetryable => false;

  @override
  List<Object?> get props => [questionId, imageBytes, fileName, mimeType];
}

class AskByPhotoTimeout extends AskByPhotoSolveFailed {
  final String questionId;

  const AskByPhotoTimeout({
    required this.questionId,
    super.imageBytes,
    super.fileName,
    super.mimeType,
  });

  @override
  bool get isRetryable => true;

  @override
  List<Object?> get props => [questionId, imageBytes, fileName, mimeType];
}

/// Not an [AskByPhotoSolveFailed]: this is raised both when the file itself is
/// wrong and when nothing was picked at all, so there is not always a photo to
/// hold on to, and resubmitting unchanged bytes cannot help either way.
class AskByPhotoValidationError extends AskByPhotoState {
  final String message;

  const AskByPhotoValidationError(this.message);

  @override
  List<Object?> get props => [message];
}

class AskByPhotoNetworkError extends AskByPhotoSolveFailed {
  final String message;

  const AskByPhotoNetworkError(
    this.message, {
    super.imageBytes,
    super.fileName,
    super.mimeType,
  });

  @override
  bool get isRetryable => true;

  @override
  List<Object?> get props => [message, imageBytes, fileName, mimeType];
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
