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

  /// Lets the student crop and rotate this photo again. Null only for photos
  /// that did not come through the picker.
  final EditablePhoto? editablePhoto;

  /// Names this photo to the API. It is made when the photo is picked or
  /// edited and sent with every try, so the API answers a retry with the
  /// first try's result instead of solving and counting the photo again.
  final String idempotencyKey;

  const AskByPhotoPhotoSelected({
    required this.imageBytes,
    required this.fileName,
    this.mimeType,
    this.editablePhoto,
    required this.idempotencyKey,
  });

  @override
  List<Object?> get props =>
      [imageBytes, fileName, mimeType, editablePhoto, idempotencyKey];
}

/// A chosen photo is being turned upright, scaled down and saved as JPEG.
class AskByPhotoPreparingPhoto extends AskByPhotoState {
  /// The photo on screen before this one was chosen, brought back if the new
  /// one cannot be prepared.
  final AskByPhotoPhotoSelected? previousSelection;

  const AskByPhotoPreparingPhoto({this.previousSelection});

  @override
  List<Object?> get props => [previousSelection];
}

class AskByPhotoLoading extends AskByPhotoState {
  /// The photo being solved, carried through so the preview stays on screen for
  /// the whole in-flight solve instead of collapsing to the empty placeholder.
  /// Null only when a submit is dispatched with nothing selected.
  final Uint8List? imageBytes;
  final String? fileName;

  /// Carried so the Crop & rotate button keeps its place, disabled, while the
  /// solve runs, and so a failure can hand it on.
  final EditablePhoto? editablePhoto;

  /// The key the photo is sent under. Null only when a submit is dispatched
  /// with nothing selected.
  final String? idempotencyKey;

  const AskByPhotoLoading({
    this.imageBytes,
    this.fileName,
    this.editablePhoto,
    this.idempotencyKey,
  });

  @override
  List<Object?> get props =>
      [imageBytes, fileName, editablePhoto, idempotencyKey];
}

class AskByPhotoSolved extends AskByPhotoState {
  final String questionId;
  final SolutionDocument solution;

  /// Solver commentary that travels with the document. Kept here because the
  /// reader is opened from this state, and dropping it here would make the
  /// note unreachable on the solve path.
  final String note;

  /// Where the solved question sits. Empty when the solver named none.
  final String topic;

  /// The theory or rule the solution relies on. Empty when unnamed.
  final String method;

  /// The questions left today after this one. Null when the answer had none.
  final DailyLimit? dailyLimit;

  const AskByPhotoSolved({
    required this.questionId,
    required this.solution,
    this.note = '',
    this.topic = '',
    this.method = '',
    this.dailyLimit,
  });

  @override
  List<Object?> get props =>
      [questionId, solution, note, topic, method, dailyLimit];
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

  /// Lets the student crop out what confused the solver and send it again.
  final EditablePhoto? editablePhoto;

  /// The key the photo was sent under. Trying again sends it again, so the
  /// API can tell a retry from a new photo.
  final String? idempotencyKey;

  const AskByPhotoSolveFailed({
    this.imageBytes,
    this.fileName,
    this.mimeType,
    this.editablePhoto,
    this.idempotencyKey,
  });

  /// Whether to offer "Try again": sending these exact bytes again could end
  /// differently.
  ///
  /// A blurry photo reads as blurry every time, so offering "Try again" there
  /// only wastes a round trip; a dropped connection is worth another go. A
  /// photo the daily limit turned away isn't retryable either, though Submit
  /// sends it again once the day resets.
  bool get isRetryable;

  /// Whether the API may hold, or still be making, an answer for this photo's
  /// key: no answer reached the student. With no questions left today, only
  /// such a photo can still be sent, because the API gives back a saved
  /// answer before it checks any limit.
  ///
  /// Not after a timeout: that answer came back, and the API saves it without
  /// the key, so it never gives it back. Nor after the daily limit turned the
  /// photo away: the API looked for a saved answer first and found none.
  bool get mayHaveAnswer => false;

  bool get hasPhoto => imageBytes != null;
}

class AskByPhotoUnreadable extends AskByPhotoSolveFailed {
  final String questionId;

  /// The questions left today after this one. Null when the answer had none.
  final DailyLimit? dailyLimit;

  const AskByPhotoUnreadable({
    required this.questionId,
    this.dailyLimit,
    super.imageBytes,
    super.fileName,
    super.mimeType,
    super.editablePhoto,
    super.idempotencyKey,
  });

  @override
  bool get isRetryable => false;

  @override
  List<Object?> get props => [
        questionId,
        dailyLimit,
        imageBytes,
        fileName,
        mimeType,
        editablePhoto,
        idempotencyKey,
      ];
}

class AskByPhotoNotAQuestion extends AskByPhotoSolveFailed {
  final String questionId;

  /// The questions left today after this one. Null when the answer had none.
  final DailyLimit? dailyLimit;

  const AskByPhotoNotAQuestion({
    required this.questionId,
    this.dailyLimit,
    super.imageBytes,
    super.fileName,
    super.mimeType,
    super.editablePhoto,
    super.idempotencyKey,
  });

  @override
  bool get isRetryable => false;

  @override
  List<Object?> get props => [
        questionId,
        dailyLimit,
        imageBytes,
        fileName,
        mimeType,
        editablePhoto,
        idempotencyKey,
      ];
}

class AskByPhotoTimeout extends AskByPhotoSolveFailed {
  final String questionId;

  /// The questions left today after this one. Null when the answer had none.
  final DailyLimit? dailyLimit;

  const AskByPhotoTimeout({
    required this.questionId,
    this.dailyLimit,
    super.imageBytes,
    super.fileName,
    super.mimeType,
    super.editablePhoto,
    super.idempotencyKey,
  });

  @override
  bool get isRetryable => true;

  @override
  List<Object?> get props => [
        questionId,
        dailyLimit,
        imageBytes,
        fileName,
        mimeType,
        editablePhoto,
        idempotencyKey,
      ];
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

/// What a failed solve ran into, so the page can say which.
enum SolveErrorCause { network, server, unknown }

class AskByPhotoNetworkError extends AskByPhotoSolveFailed {
  final String message;
  final SolveErrorCause cause;

  const AskByPhotoNetworkError(
    this.message, {
    this.cause = SolveErrorCause.unknown,
    super.imageBytes,
    super.fileName,
    super.mimeType,
    super.editablePhoto,
    super.idempotencyKey,
  });

  @override
  bool get isRetryable => true;

  /// The API may have saved an answer that never reached the student.
  @override
  bool get mayHaveAnswer => true;

  @override
  List<Object?> get props => [
        message,
        cause,
        imageBytes,
        fileName,
        mimeType,
        editablePhoto,
        idempotencyKey,
      ];
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

/// The API turned the photo away: a photo the student sent, perhaps this
/// one, is still being solved. The photo stays, and Try again sends it under
/// the same key.
class AskByPhotoStillSolving extends AskByPhotoSolveFailed {
  const AskByPhotoStillSolving({
    super.imageBytes,
    super.fileName,
    super.mimeType,
    super.editablePhoto,
    super.idempotencyKey,
  });

  @override
  bool get isRetryable => true;

  /// The photo still being solved may be this one.
  @override
  bool get mayHaveAnswer => true;

  @override
  List<Object?> get props =>
      [imageBytes, fileName, mimeType, editablePhoto, idempotencyKey];
}

/// The API turned the photo away: the student has no questions left today.
///
/// Not retryable, so nothing offers to send it again while the limit holds.
/// The photo and its key stay, and a submit sends them once the day resets.
class AskByPhotoLimitReached extends AskByPhotoSolveFailed {
  /// None left, and when they come back.
  final DailyLimit dailyLimit;

  const AskByPhotoLimitReached({
    required this.dailyLimit,
    super.imageBytes,
    super.fileName,
    super.mimeType,
    super.editablePhoto,
    super.idempotencyKey,
  });

  @override
  bool get isRetryable => false;

  @override
  List<Object?> get props => [
        dailyLimit,
        imageBytes,
        fileName,
        mimeType,
        editablePhoto,
        idempotencyKey,
      ];
}
