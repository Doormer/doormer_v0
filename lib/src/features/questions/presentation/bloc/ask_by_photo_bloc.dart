import 'package:bloc/bloc.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/usecase/submit_photo_question_usecase.dart';
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
  }

  void _onPhotoPicked(
    AskByPhotoPhotoPicked event,
    Emitter<AskByPhotoState> emit,
  ) {
    emit(AskByPhotoPhotoSelected(
      imageBytes: event.imageBytes,
      fileName: event.fileName,
      mimeType: event.mimeType,
    ));
  }

  Future<void> _onSubmitted(
    AskByPhotoSubmitted event,
    Emitter<AskByPhotoState> emit,
  ) async {
    final selectedState = state;
    emit(const AskByPhotoLoading());

    if (selectedState is! AskByPhotoPhotoSelected) {
      emit(const AskByPhotoValidationError(
        'Please choose a JPEG or PNG photo before submitting.',
      ));
      return;
    }

    try {
      final outcome = await submitPhotoQuestionUseCase(
        imageBytes: selectedState.imageBytes,
        fileName: selectedState.fileName,
        mimeType: selectedState.mimeType,
      );
      _emitOutcome(outcome, emit);
    } on ValidationFailure catch (f, stackTrace) {
      emit(AskByPhotoValidationError(f.message));
      AppLogger.error('Photo question validation failed',
          error: f, stackTrace: stackTrace);
    } on Failure catch (f, stackTrace) {
      emit(AskByPhotoNetworkError(f.message));
      AppLogger.error('Photo question submission failed',
          error: f, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      emit(const AskByPhotoNetworkError('An unexpected error occurred'));
      AppLogger.error('Photo question unexpected error',
          error: e, stackTrace: stackTrace);
    }
  }

  void _emitOutcome(
    PhotoQuestionSolveOutcome outcome,
    Emitter<AskByPhotoState> emit,
  ) {
    switch (outcome.status) {
      case PhotoQuestionSolveStatus.solved:
        final solution = outcome.solution;
        if (solution == null) {
          emit(const AskByPhotoNetworkError(
            'We could not read the solver response. Try again.',
          ));
          return;
        }
        emit(AskByPhotoSolved(
          questionId: outcome.questionId,
          solution: solution,
        ));
      case PhotoQuestionSolveStatus.unreadable:
        emit(AskByPhotoUnreadable(questionId: outcome.questionId));
      case PhotoQuestionSolveStatus.notAQuestion:
        emit(AskByPhotoNotAQuestion(questionId: outcome.questionId));
      case PhotoQuestionSolveStatus.timeout:
        emit(AskByPhotoTimeout(questionId: outcome.questionId));
    }
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
    final previousState = state;
    emit(AskByPhotoNotice(message));

    if (previousState is AskByPhotoPhotoSelected) {
      emit(previousState);
    }
  }
}
