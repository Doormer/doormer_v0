import 'package:bloc/bloc.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/usecase/submit_photo_question_usecase.dart';
import 'package:doormer/src/features/questions/utils/photo/editable_photo.dart';
import 'package:doormer/src/features/questions/utils/photo_question_image_validator.dart';
import 'package:equatable/equatable.dart';
import 'dart:typed_data';

part 'ask_by_photo_event.dart';
part 'ask_by_photo_state.dart';

class AskByPhotoBloc extends Bloc<AskByPhotoEvent, AskByPhotoState> {
  final SubmitPhotoQuestionUseCase submitPhotoQuestionUseCase;

  AskByPhotoBloc({required this.submitPhotoQuestionUseCase})
      : super(const AskByPhotoInitial()) {
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
      );
      _emitOutcome(outcome, selected, emit);
    } on ValidationFailure catch (f, stackTrace) {
      emit(AskByPhotoValidationError(f.message));
      AppLogger.error('Photo question validation failed',
          error: f, stackTrace: stackTrace);
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
  _PhotoInHand? _photoInHand() {
    final current = state;
    if (current is AskByPhotoPhotoSelected) {
      return _PhotoInHand(
        imageBytes: current.imageBytes,
        fileName: current.fileName,
        mimeType: current.mimeType,
        editablePhoto: current.editablePhoto,
      );
    }
    if (current is AskByPhotoSolveFailed && current.isRetryable) {
      final bytes = current.imageBytes;
      if (bytes != null) {
        return _PhotoInHand(
          imageBytes: bytes,
          fileName: current.fileName ?? 'photo.jpg',
          mimeType: current.mimeType,
          editablePhoto: current.editablePhoto,
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
          ));
          return;
        }
        emit(AskByPhotoSolved(
          questionId: outcome.questionId,
          solution: solution,
          note: outcome.note,
          topic: outcome.topic,
          method: outcome.method,
        ));
      case PhotoQuestionSolveStatus.unreadable:
        emit(AskByPhotoUnreadable(
          questionId: outcome.questionId,
          imageBytes: photo.imageBytes,
          fileName: photo.fileName,
          mimeType: photo.mimeType,
          editablePhoto: photo.editablePhoto,
        ));
      case PhotoQuestionSolveStatus.notAQuestion:
        emit(AskByPhotoNotAQuestion(
          questionId: outcome.questionId,
          imageBytes: photo.imageBytes,
          fileName: photo.fileName,
          mimeType: photo.mimeType,
          editablePhoto: photo.editablePhoto,
        ));
      case PhotoQuestionSolveStatus.timeout:
        emit(AskByPhotoTimeout(
          questionId: outcome.questionId,
          imageBytes: photo.imageBytes,
          fileName: photo.fileName,
          mimeType: photo.mimeType,
          editablePhoto: photo.editablePhoto,
        ));
    }
  }

  void _onPreparationStarted(
    AskByPhotoPreparationStarted event,
    Emitter<AskByPhotoState> emit,
  ) {
    emit(AskByPhotoPreparingPhoto(previousSelection: _currentSelection()));
  }

  /// The photo on screen now, or the one a preparation in progress replaced.
  ///
  /// A failed solve's photo counts: editing it prepares it again, and if that
  /// fails the photo must come back rather than vanish.
  AskByPhotoPhotoSelected? _currentSelection() {
    final current = state;
    if (current is AskByPhotoPhotoSelected) return current;
    if (current is AskByPhotoPreparingPhoto) return current.previousSelection;
    if (current is AskByPhotoSolveFailed) {
      final bytes = current.imageBytes;
      if (bytes != null) {
        return AskByPhotoPhotoSelected(
          imageBytes: bytes,
          fileName: current.fileName ?? 'photo.jpg',
          mimeType: current.mimeType,
          editablePhoto: current.editablePhoto,
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
    _emitNoticePreservingSelection('No photo selected.', emit);
  }

  void _onPickUnavailable(
    AskByPhotoPickUnavailable event,
    Emitter<AskByPhotoState> emit,
  ) {
    _emitNoticePreservingSelection(event.message, emit);
  }

  void _emitNoticePreservingSelection(
    String message,
    Emitter<AskByPhotoState> emit,
  ) {
    final selection = _currentSelection();
    emit(AskByPhotoNotice(message));

    if (selection != null) {
      emit(selection);
    }
  }
}

/// The photo a submit is acting on, flattened out of whichever state was
/// holding it so the submit path does not care where it came from.
class _PhotoInHand {
  final Uint8List imageBytes;
  final String fileName;
  final String? mimeType;
  final EditablePhoto? editablePhoto;

  const _PhotoInHand({
    required this.imageBytes,
    required this.fileName,
    this.mimeType,
    this.editablePhoto,
  });
}
