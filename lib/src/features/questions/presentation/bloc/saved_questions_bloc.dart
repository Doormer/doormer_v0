import 'package:bloc/bloc.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entity/solved_question_summary.dart';
import '../../domain/usecase/load_solved_questions_usecase.dart';

part 'saved_questions_event.dart';
part 'saved_questions_state.dart';

/// Loads the student's solved questions for the Saved list, a page at a time.
///
/// Handlers run concurrently. A request for more that arrives while a page is
/// on its way is dropped by reading the state, which the first request marked
/// as loading before it awaited anything.
class SavedQuestionsBloc
    extends Bloc<SavedQuestionsEvent, SavedQuestionsState> {
  static const couldNotLoad = "We couldn't load your questions.";

  final LoadSolvedQuestionsUseCase loadSolvedQuestions;

  SavedQuestionsBloc({required this.loadSolvedQuestions})
      : super(const SavedQuestionsLoading()) {
    on<SavedQuestionsStarted>(_onStarted);
    on<SavedQuestionsMoreRequested>(_onMoreRequested);
    on<SavedQuestionsRetried>(_onRetried);
  }

  Future<void> _onStarted(
    SavedQuestionsStarted event,
    Emitter<SavedQuestionsState> emit,
  ) =>
      _loadFirstPage(emit);

  Future<void> _onMoreRequested(
    SavedQuestionsMoreRequested event,
    Emitter<SavedQuestionsState> emit,
  ) async {
    final current = state;
    if (current is! SavedQuestionsReady ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.loadMoreFailed) {
      return;
    }
    await _loadNextPage(current, emit);
  }

  Future<void> _onRetried(
    SavedQuestionsRetried event,
    Emitter<SavedQuestionsState> emit,
  ) async {
    final current = state;
    if (current is SavedQuestionsError) {
      await _loadFirstPage(emit);
    } else if (current is SavedQuestionsReady &&
        current.loadMoreFailed &&
        !current.isLoadingMore) {
      await _loadNextPage(current, emit);
    }
  }

  Future<void> _loadFirstPage(Emitter<SavedQuestionsState> emit) async {
    if (state is! SavedQuestionsLoading) emit(const SavedQuestionsLoading());
    try {
      final page = await loadSolvedQuestions();
      emit(page.questions.isEmpty
          ? const SavedQuestionsEmpty()
          : SavedQuestionsReady(
              questions: page.questions,
              nextCursor: page.nextCursor,
            ));
    } on Failure catch (f, stackTrace) {
      AppLogger.error('Saved questions failed to load',
          error: f, stackTrace: stackTrace);
      emit(const SavedQuestionsError(couldNotLoad));
    } catch (e, stackTrace) {
      AppLogger.error('Saved questions failed unexpectedly',
          error: e, stackTrace: stackTrace);
      emit(const SavedQuestionsError(couldNotLoad));
    }
  }

  Future<void> _loadNextPage(
    SavedQuestionsReady current,
    Emitter<SavedQuestionsState> emit,
  ) async {
    emit(current.copyWith(isLoadingMore: true, loadMoreFailed: false));
    try {
      final page = await loadSolvedQuestions(cursor: current.nextCursor);
      emit(SavedQuestionsReady(
        questions: [...current.questions, ...page.questions],
        nextCursor: page.nextCursor,
      ));
    } on Failure catch (f, stackTrace) {
      AppLogger.error('More saved questions failed to load',
          error: f, stackTrace: stackTrace);
      emit(current.copyWith(isLoadingMore: false, loadMoreFailed: true));
    } catch (e, stackTrace) {
      AppLogger.error('More saved questions failed unexpectedly',
          error: e, stackTrace: stackTrace);
      emit(current.copyWith(isLoadingMore: false, loadMoreFailed: true));
    }
  }
}
