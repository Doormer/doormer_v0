import 'package:bloc/bloc.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/quest_profile.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_quark_balance_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_quest_profile_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_sample_solution_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/reveal_answer_usecase.dart';
import 'package:equatable/equatable.dart';

part 'solution_reader_event.dart';
part 'solution_reader_state.dart';

class SolutionReaderBloc
    extends Bloc<SolutionReaderEvent, SolutionReaderState> {
  final LoadSampleSolutionUseCase loadSampleSolutionUseCase;
  final LoadQuestProfileUseCase loadQuestProfileUseCase;
  final LoadQuarkBalanceUseCase loadQuarkBalanceUseCase;
  final RevealAnswerUseCase revealAnswerUseCase;

  SolutionReaderBloc({
    required this.loadSampleSolutionUseCase,
    required this.loadQuestProfileUseCase,
    required this.loadQuarkBalanceUseCase,
    required this.revealAnswerUseCase,
  }) : super(const SolutionReaderInitial()) {
    on<SolutionReaderStarted>(_onStarted);
    on<SolutionReaderAdvanced>(_onAdvanced);
    on<SolutionReaderWentBack>(_onWentBack);
    on<SolutionReaderTravelled>(_onTravelled);
    on<SolutionReaderRationaleToggled>(_onRationaleToggled);
    on<SolutionReaderAnswerRevealed>(_onAnswerRevealed);
  }

  Future<void> _onStarted(
    SolutionReaderStarted event,
    Emitter<SolutionReaderState> emit,
  ) async {
    final handedOver = event.document;
    if (handedOver != null) {
      emit(SolutionReaderReady(
        document: handedOver,
        onBriefing: handedOver.approach.body.isNotEmpty,
        note: event.note,
      ));
      await _attachQuarkBalance(emit);
      await _attachProfile(emit);
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
      emit(SolutionReaderReady(
        document: solution,
        onBriefing: solution.approach.body.isNotEmpty,
        note: outcome.note,
      ));
      await _attachQuarkBalance(emit);
      await _attachProfile(emit);
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

  /// Loads the real quark balance behind the solution. Failure hides the pill
  /// and is logged; it must not cost the student the solution.
  Future<void> _attachQuarkBalance(Emitter<SolutionReaderState> emit) async {
    final current = state;
    if (current is! SolutionReaderReady) return;
    try {
      final balance = await loadQuarkBalanceUseCase();
      final latest = state;
      if (latest is SolutionReaderReady) {
        emit(latest.copyWith(quarkBalance: balance));
      }
    } catch (e, stackTrace) {
      AppLogger.error('Quark balance load failed',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Loads the student's standing behind the solution. A missing profile costs
  /// the HUD its pills; it must never cost the student the solution, so a
  /// failure here is logged and swallowed rather than surfaced as an error
  /// state.
  Future<void> _attachProfile(Emitter<SolutionReaderState> emit) async {
    final current = state;
    if (current is! SolutionReaderReady) return;
    try {
      final profile = await loadQuestProfileUseCase();
      final latest = state;
      if (latest is SolutionReaderReady) {
        emit(latest.copyWith(profile: profile));
      }
    } catch (e, stackTrace) {
      AppLogger.error('Quest profile load failed',
          error: e, stackTrace: stackTrace);
    }
  }

  void _onAdvanced(
    SolutionReaderAdvanced event,
    Emitter<SolutionReaderState> emit,
  ) {
    final current = state;
    if (current is! SolutionReaderReady) {
      return;
    }
    // The briefing check must come before isLastStep. In a one-step solution
    // isLastStep is already true at stepIndex 0, so testing it first would
    // strand the student on the briefing forever.
    if (current.onBriefing) {
      emit(current.copyWith(onBriefing: false, rationaleVisible: false));
      return;
    }
    if (current.isLastStep) {
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
    if (current is! SolutionReaderReady || current.onBriefing) {
      return;
    }
    if (current.isFirstStep) {
      if (!current.hasBriefing) {
        return;
      }
      emit(current.copyWith(onBriefing: true, rationaleVisible: false));
      return;
    }
    emit(current.copyWith(
      stepIndex: current.stepIndex - 1,
      rationaleVisible: false,
    ));
  }

  /// Travel is backwards only, so the trail stays a record of ground covered
  /// rather than a way around the working.
  void _onTravelled(
    SolutionReaderTravelled event,
    Emitter<SolutionReaderState> emit,
  ) {
    final current = state;
    if (current is! SolutionReaderReady) return;

    final here = current.onBriefing
        ? SolutionReaderTravelled.briefing
        : current.stepIndex;
    final there = event.position;
    if (there >= here || there < SolutionReaderTravelled.briefing) return;

    if (there == SolutionReaderTravelled.briefing) {
      if (!current.hasBriefing) return;
      emit(current.copyWith(onBriefing: true, rationaleVisible: false));
      return;
    }
    emit(current.copyWith(
      onBriefing: false,
      stepIndex: there,
      rationaleVisible: false,
    ));
  }

  void _onRationaleToggled(
    SolutionReaderRationaleToggled event,
    Emitter<SolutionReaderState> emit,
  ) {
    final current = state;
    if (current is! SolutionReaderReady || current.onBriefing) return;
    emit(current.copyWith(rationaleVisible: !current.rationaleVisible));
  }

  Future<void> _onAnswerRevealed(
    SolutionReaderAnswerRevealed event,
    Emitter<SolutionReaderState> emit,
  ) async {
    final current = state;
    // onBriefing is checked because a one-step solution is on its last step
    // while the briefing is still showing; without it the answer could be
    // revealed before a single step is read.
    if (current is! SolutionReaderReady ||
        current.onBriefing ||
        !current.isLastStep ||
        current.answerRevealed) {
      return;
    }

    emit(current.copyWith(
      answerRevealed: true,
      revealRewardRequested:
          current.revealRewardRequested || event.questionId != null,
    ));

    final questionId = event.questionId;
    if (questionId == null || current.revealRewardRequested) return;

    try {
      final reward = await revealAnswerUseCase(questionId);
      final latest = state;
      if (latest is! SolutionReaderReady) return;
      final hadVisibleBalance = current.quarkBalance != null;
      emit(latest.copyWith(
        quarkBalance: reward.quarkBalance,
        quarksEarned: reward.quarksEarned,
        rewardFlightId: hadVisibleBalance && reward.quarksEarned > 0
            ? latest.rewardFlightId + 1
            : latest.rewardFlightId,
      ));
    } catch (e, stackTrace) {
      AppLogger.error('Answer reveal reward failed',
          error: e, stackTrace: stackTrace);
    }
  }
}
