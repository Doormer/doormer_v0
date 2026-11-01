import 'package:bloc/bloc.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/domain/entity/daily_limit.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/failure/photo_question_failures.dart';
import 'package:doormer/src/features/questions/domain/usecase/submit_photo_question_usecase.dart';
import 'package:doormer/src/features/questions/utils/photo/editable_photo.dart';
import 'package:doormer/src/features/questions/utils/photo_question_image_validator.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';

part 'ask_by_photo_event.dart';
part 'ask_by_photo_state.dart';

class AskByPhotoBloc extends Bloc<AskByPhotoEvent, AskByPhotoState> {
  final SubmitPhotoQuestionUseCase submitPhotoQuestionUseCase;

  /// Makes the key for a newly picked or edited photo. Tests pass their own
  /// to know which key each photo gets.
  final String Function() newIdempotencyKey;

  AskByPhotoBloc({
    required this.submitPhotoQuestionUseCase,
    String Function()? newIdempotencyKey,
  })  : newIdempotencyKey = newIdempotencyKey ?? _newUuid,
        super(const AskByPhotoInitial()) {
    on<AskByPhotoPhotoPicked>(_onPhotoPicked);
    on<AskByPhotoSubmitted>(_onSubmitted);
    on<AskByPhotoClearRequested>(_onClearRequested);
    on<AskByPhotoTypeInsteadRequested>(_onTypeInsteadRequested);
    on<AskByPhotoPickCancelled>(_onPickCancelled);
    on<AskByPhotoPickUnavailable>(_onPickUnavailable);
    on<AskByPhotoPreparationStarted>(_onPreparationStarted);
  }

  void _onPhotoPicked(
    AskByPhotoPhotoPicked event,
    Emitter<AskByPhotoState> emit,
  ) {
    emit(AskByPhotoPhotoSelected(
      imageBytes: event.imageBytes,
      fileName: event.fileName,
      mimeType: event.mimeType,
      editablePhoto: event.editablePhoto,
      // A picked or edited photo is a new submission, so it gets a new key.
      idempotencyKey: newIdempotencyKey(),
    ));
  }

  Future<void> _onSubmitted(
    AskByPhotoSubmitted event,
    Emitter<AskByPhotoState> emit,
  ) async {
    // The panel disables Submit while preparing; this guards a stray event.
    if (state is AskByPhotoPreparingPhoto) return;

    final selected = _photoInHand();
    emit(AskByPhotoLoading(
      imageBytes: selected?.imageBytes,
      fileName: selected?.fileName,
      editablePhoto: selected?.editablePhoto,
      idempotencyKey: selected?.idempotencyKey,
    ));

    if (selected == null) {
      emit(const AskByPhotoValidationError(
        PhotoQuestionImageValidator.missingImageMessage,
      ));
      return;
    }

    try {
      final outcome = await submitPhotoQuestionUseCase(
        imageBytes: selected.imageBytes,
        fileName: selected.fileName,
        mimeType: selected.mimeType,
        idempotencyKey: selected.idempotencyKey,
      );
      _emitOutcome(outcome, selected, emit);
    } on ValidationFailure catch (f, stackTrace) {
      emit(AskByPhotoValidationError(f.message));
      AppLogger.error('Photo question validation failed',
          error: f, stackTrace: stackTrace);
    } on DailyLimitReachedFailure catch (f) {
      emit(AskByPhotoLimitReached(
        dailyLimit: f.dailyLimit,
        imageBytes: selected.imageBytes,
        fileName: selected.fileName,
        mimeType: selected.mimeType,
        editablePhoto: selected.editablePhoto,
        idempotencyKey: selected.idempotencyKey,
      ));
      AppLogger.info('Photo question refused: no questions left today');
    } on PhotoBeingSolvedFailure {
      emit(AskByPhotoStillSolving(
        imageBytes: selected.imageBytes,
        fileName: selected.fileName,
        mimeType: selected.mimeType,
        editablePhoto: selected.editablePhoto,
        idempotencyKey: selected.idempotencyKey,
      ));
      AppLogger.info('Photo question refused: a photo is being solved');
    } on Failure catch (f, stackTrace) {
      emit(AskByPhotoNetworkError(
        f.message,
        cause: switch (f) {
          NetworkFailure() => SolveErrorCause.network,
          ServerFailure() => SolveErrorCause.server,
          _ => SolveErrorCause.unknown,
        },
        imageBytes: selected.imageBytes,
        fileName: selected.fileName,
        mimeType: selected.mimeType,
        editablePhoto: selected.editablePhoto,
        idempotencyKey: selected.idempotencyKey,
      ));
      AppLogger.error('Photo question submission failed',
          error: f, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      emit(AskByPhotoNetworkError(
        'An unexpected error occurred',
        cause: SolveErrorCause.unknown,
        imageBytes: selected.imageBytes,
        fileName: selected.fileName,
        mimeType: selected.mimeType,
        editablePhoto: selected.editablePhoto,
        idempotencyKey: selected.idempotencyKey,
      ));
      AppLogger.error('Photo question unexpected error',
          error: e, stackTrace: stackTrace);
    }
  }

  /// The photo a submit should act on, whether it was just picked or is being
  /// retried after a failure that kept it.
  ///
  /// Reading only [AskByPhotoPhotoSelected] here is what used to make a retry
  /// report "choose a photo first" over a photo already on screen.
  ///
  /// A photo the daily limit turned away is in hand too: it is sent once the
  /// day resets, and the page keeps Submit off until then.
  _PhotoInHand? _photoInHand() {
    final current = state;
    if (current is AskByPhotoPhotoSelected) {
      return _PhotoInHand(
        imageBytes: current.imageBytes,
        fileName: current.fileName,
        mimeType: current.mimeType,
        editablePhoto: current.editablePhoto,
        idempotencyKey: current.idempotencyKey,
      );
    }
    if (current is AskByPhotoSolveFailed &&
        (current.isRetryable || current is AskByPhotoLimitReached)) {
      final bytes = current.imageBytes;
      if (bytes != null) {
        return _PhotoInHand(
          imageBytes: bytes,
          fileName: current.fileName ?? 'photo.jpg',
          mimeType: current.mimeType,
          editablePhoto: current.editablePhoto,
          idempotencyKey: current.idempotencyKey ?? newIdempotencyKey(),
        );
      }
    }
    return null;
  }

  void _emitOutcome(
    PhotoQuestionSolveOutcome outcome,
    _PhotoInHand photo,
    Emitter<AskByPhotoState> emit,
  ) {
    switch (outcome.status) {
      case PhotoQuestionSolveStatus.solved:
        final solution = outcome.solution;
        if (solution == null) {
          emit(AskByPhotoNetworkError(
            'We could not read the solver response. Try again.',
            imageBytes: photo.imageBytes,
            fileName: photo.fileName,
            mimeType: photo.mimeType,
            editablePhoto: photo.editablePhoto,
            idempotencyKey: photo.idempotencyKey,
          ));
          return;
        }
        emit(AskByPhotoSolved(
          questionId: outcome.questionId,
          solution: solution,
          note: outcome.note,
          topic: outcome.topic,
          method: outcome.method,
          dailyLimit: outcome.dailyLimit,
        ));
      case PhotoQuestionSolveStatus.unreadable:
        emit(AskByPhotoUnreadable(
          questionId: outcome.questionId,
          dailyLimit: outcome.dailyLimit,
          imageBytes: photo.imageBytes,
          fileName: photo.fileName,
          mimeType: photo.mimeType,
          editablePhoto: photo.editablePhoto,
          idempotencyKey: photo.idempotencyKey,
        ));
      case PhotoQuestionSolveStatus.notAQuestion:
        emit(AskByPhotoNotAQuestion(
          questionId: outcome.questionId,
          dailyLimit: outcome.dailyLimit,
          imageBytes: photo.imageBytes,
          fileName: photo.fileName,
          mimeType: photo.mimeType,
          editablePhoto: photo.editablePhoto,
          idempotencyKey: photo.idempotencyKey,
        ));
      case PhotoQuestionSolveStatus.timeout:
        emit(AskByPhotoTimeout(
          questionId: outcome.questionId,
          dailyLimit: outcome.dailyLimit,
          imageBytes: photo.imageBytes,
          fileName: photo.fileName,
          mimeType: photo.mimeType,
          editablePhoto: photo.editablePhoto,
          idempotencyKey: photo.idempotencyKey,
        ));
    }
  }

  void _onPreparationStarted(
    AskByPhotoPreparationStarted event,
    Emitter<AskByPhotoState> emit,
  ) {
    emit(AskByPhotoPreparingPhoto(previous: _stateToRestore()));
  }

  /// What a cancelled pick, or a photo that can't be prepared, brings back:
  /// the photo on screen, or what a preparation in progress replaced.
  ///
  /// A failed send that may have an answer comes back as it was. It keeps
  /// offering Try again under its key, even with no questions left today,
  /// because the API gives back the answer it saved under that key. Any
  /// other failed send comes back as a plain photo under its key, so the
  /// photo doesn't vanish.
  AskByPhotoState? _stateToRestore() {
    final current = state;
    if (current is AskByPhotoPhotoSelected) return current;
    if (current is AskByPhotoPreparingPhoto) return current.previous;
    if (current is AskByPhotoSolveFailed) {
      if (current.mayHaveAnswer && current.hasPhoto) return current;
      final bytes = current.imageBytes;
      if (bytes != null) {
        return AskByPhotoPhotoSelected(
          imageBytes: bytes,
          fileName: current.fileName ?? 'photo.jpg',
          mimeType: current.mimeType,
          editablePhoto: current.editablePhoto,
          idempotencyKey: current.idempotencyKey ?? newIdempotencyKey(),
        );
      }
    }
    return null;
  }

  void _onClearRequested(
    AskByPhotoClearRequested event,
    Emitter<AskByPhotoState> emit,
  ) {
    emit(const AskByPhotoInitial());
  }

  void _onTypeInsteadRequested(
    AskByPhotoTypeInsteadRequested event,
    Emitter<AskByPhotoState> emit,
  ) {
    emit(const AskByPhotoTypeInstead());
  }

  void _onPickCancelled(
    AskByPhotoPickCancelled event,
    Emitter<AskByPhotoState> emit,
  ) {
    _emitNoticeAndRestore('No photo selected.', emit);
  }

  void _onPickUnavailable(
    AskByPhotoPickUnavailable event,
    Emitter<AskByPhotoState> emit,
  ) {
    _emitNoticeAndRestore(event.message, emit);
  }

  /// Emits the Notice right before what is brought back: the page relies on
  /// that order to tell a failed send brought back from one that just ended.
  void _emitNoticeAndRestore(String message, Emitter<AskByPhotoState> emit) {
    final restored = _stateToRestore();
    emit(AskByPhotoNotice(message));
    if (restored != null) emit(restored);
  }
}

/// The photo a submit is acting on, flattened out of whichever state was
/// holding it so the submit path does not care where it came from.
class _PhotoInHand {
  final Uint8List imageBytes;
  final String fileName;
  final String? mimeType;
  final EditablePhoto? editablePhoto;
  final String idempotencyKey;

  const _PhotoInHand({
    required this.imageBytes,
    required this.fileName,
    this.mimeType,
    this.editablePhoto,
    required this.idempotencyKey,
  });
}

String _newUuid() => const Uuid().v4();
