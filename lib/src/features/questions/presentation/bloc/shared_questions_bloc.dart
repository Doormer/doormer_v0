import 'package:bloc/bloc.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/shared/friends/friends_messages.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entity/shared_question_summary.dart';
import '../../domain/entity/shared_questions_page.dart';
import '../../domain/usecase/load_shared_questions_usecase.dart';

part 'shared_questions_event.dart';
part 'shared_questions_state.dart';

/// Loads Shared with me, the questions friends shared with the student, a
/// page at a time. Each next page starts where the API's `next_cursor` says,
/// sent back as it came.
///
/// Handlers run concurrently. A request for more that arrives while a page is
/// on its way is dropped by reading the state, which the first request marked
/// as loading before it awaited anything.
class SharedQuestionsBloc
    extends Bloc<SharedQuestionsEvent, SharedQuestionsState> {
  final LoadSharedQuestionsUseCase loadSharedQuestions;

  SharedQuestionsBloc({required this.loadSharedQuestions})
      : super(const SharedQuestionsLoading()) {
    on<SharedQuestionsStarted>(_onStarted);
    on<SharedQuestionsMoreRequested>(_onMoreRequested);
    on<SharedQuestionsRetried>(_onRetried);
    on<SharedQuestionsRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onStarted(
    SharedQuestionsStarted event,
    Emitter<SharedQuestionsState> emit,
  ) =>
      _loadFirstPage(emit);

  Future<void> _onMoreRequested(
    SharedQuestionsMoreRequested event,
    Emitter<SharedQuestionsState> emit,
  ) async {
    final current = state;
    if (current is! SharedQuestionsReady ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.loadMoreFailed) {
      return;
    }
    await _loadNextPage(current, emit);
  }

  Future<void> _onRetried(
    SharedQuestionsRetried event,
    Emitter<SharedQuestionsState> emit,
  ) async {
    final current = state;
    if (current is SharedQuestionsError) {
      await _loadFirstPage(emit);
    } else if (current is SharedQuestionsReady &&
        current.loadMoreFailed &&
        !current.isLoadingMore) {
      await _loadNextPage(current, emit);
    }
  }

  /// Reads the first page again and shows it as it is now, so a question
  /// removed, or no longer shared, goes, and one shared since comes in. Any
  /// later pages shown go too; scrolling loads them again.
  ///
  /// Quiet: no spinner, and a failure leaves the list as it was. The answer
  /// is dropped if anything changed while it was on its way.
  ///
  /// After a failed load, it tries again as Try again does instead.
  Future<void> _onRefreshRequested(
    SharedQuestionsRefreshRequested event,
    Emitter<SharedQuestionsState> emit,
  ) async {
    final opened = state;
    if (opened is SharedQuestionsError) {
      await _loadFirstPage(emit);
      return;
    }
    if (opened is SharedQuestionsLoading) return;
    if (opened is SharedQuestionsReady && opened.isLoadingMore) return;

    final SharedQuestionsPage page;
    try {
      page = await loadSharedQuestions();
    } catch (e) {
      AppLogger.info('Shared with me not refreshed: $e');
      return;
    }
    if (state != opened) return;
    emit(_firstPageState(page));
  }

  Future<void> _loadFirstPage(Emitter<SharedQuestionsState> emit) async {
    if (state is! SharedQuestionsLoading) emit(const SharedQuestionsLoading());
    try {
      emit(_firstPageState(await loadSharedQuestions()));
    } on Failure catch (f, stackTrace) {
      AppLogger.error('Shared with me failed to load',
          error: f, stackTrace: stackTrace);
      emit(const SharedQuestionsError(
          FriendsMessages.couldNotLoadSharedQuestions));
    } catch (e, stackTrace) {
      AppLogger.error('Shared with me failed unexpectedly',
          error: e, stackTrace: stackTrace);
      emit(const SharedQuestionsError(
          FriendsMessages.couldNotLoadSharedQuestions));
    }
  }

  Future<void> _loadNextPage(
    SharedQuestionsReady current,
    Emitter<SharedQuestionsState> emit,
  ) async {
    emit(current.copyWith(isLoadingMore: true, loadMoreFailed: false));
    try {
      final page = await loadSharedQuestions(cursor: current.nextCursor);
      emit(SharedQuestionsReady(
        questions: [...current.questions, ...page.questions],
        nextCursor: page.nextCursor,
      ));
    } on Failure catch (f, stackTrace) {
      AppLogger.error('More of Shared with me failed to load',
          error: f, stackTrace: stackTrace);
      emit(current.copyWith(isLoadingMore: false, loadMoreFailed: true));
    } catch (e, stackTrace) {
      AppLogger.error('More of Shared with me failed unexpectedly',
          error: e, stackTrace: stackTrace);
      emit(current.copyWith(isLoadingMore: false, loadMoreFailed: true));
    }
  }

  static SharedQuestionsState _firstPageState(SharedQuestionsPage page) =>
      page.questions.isEmpty
          ? const SharedQuestionsEmpty()
          : SharedQuestionsReady(
              questions: page.questions,
              nextCursor: page.nextCursor,
            );
}
