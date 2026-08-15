import 'package:bloc/bloc.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_sample_solution_usecase.dart';
import 'package:equatable/equatable.dart';

part 'solution_reader_event.dart';
part 'solution_reader_state.dart';

class SolutionReaderBloc extends Bloc<SolutionReaderEvent, SolutionReaderState> {
  final LoadSampleSolutionUseCase loadSampleSolutionUseCase;

  SolutionReaderBloc({required this.loadSampleSolutionUseCase})
      : super(const SolutionReaderInitial()) {
    on<SolutionReaderStarted>(_onStarted);
    on<SolutionReaderAdvanced>(_onAdvanced);
    on<SolutionReaderWentBack>(_onWentBack);
    on<SolutionReaderRationaleToggled>(_onRationaleToggled);
    on<SolutionReaderAnswerRevealed>(_onAnswerRevealed);
  }

  Future<void> _onStarted(
    SolutionReaderStarted event,
    Emitter<SolutionReaderState> emit,
  ) async {
    final handedOver = event.document;
    if (handedOver != null) {
      emit(SolutionReaderReady(document: handedOver));
      return;
    }

    emit(const SolutionReaderLoading());
    try {
      final outcome = await loadSampleSolutionUseCase();
      final solution = outcome.solution;
      if (solution == null) {
        emit(const SolutionReaderError('This question has no solution yet.'));
        return;
      }
      emit(SolutionReaderReady(document: solution));
    } on Failure catch (f, stackTrace) {
      emit(SolutionReaderError(f.message));
      AppLogger.error('Solution reader load failed',
          error: f, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      emit(const SolutionReaderError('We could not open this solution.'));
      AppLogger.error('Solution reader unexpected error',
          error: e, stackTrace: stackTrace);
    }
  }

  void _onAdvanced(
    SolutionReaderAdvanced event,
    Emitter<SolutionReaderState> emit,
  ) {
    final current = state;
    if (current is! SolutionReaderReady || current.isLastStep) {
      return;
    }
    emit(current.copyWith(
      stepIndex: current.stepIndex + 1,
      rationaleVisible: false,
    ));
  }

  void _onWentBack(
    SolutionReaderWentBack event,
    Emitter<SolutionReaderState> emit,
  ) {
    final current = state;
    if (current is! SolutionReaderReady || current.isFirstStep) {
      return;
    }
    emit(current.copyWith(
      stepIndex: current.stepIndex - 1,
      rationaleVisible: false,
    ));
  }

  void _onRationaleToggled(
    SolutionReaderRationaleToggled event,
    Emitter<SolutionReaderState> emit,
  ) {
    final current = state;
    if (current is! SolutionReaderReady) return;
    emit(current.copyWith(rationaleVisible: !current.rationaleVisible));
  }

  void _onAnswerRevealed(
    SolutionReaderAnswerRevealed event,
    Emitter<SolutionReaderState> emit,
  ) {
    final current = state;
    if (current is! SolutionReaderReady ||
        !current.isLastStep ||
        current.answerRevealed) {
      return;
    }
    emit(current.copyWith(answerRevealed: true));
  }
}
