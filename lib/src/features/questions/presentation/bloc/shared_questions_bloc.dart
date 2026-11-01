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
/// as loading before it awaited anything. Each answer applies to the rows as
/// they stand once it arrives: one read for rows no longer showing is
/// dropped.
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

  /// Reads again as many rows as are showing, from the first page on,
  /// following `next_cursor`, and swaps them in at once, ending where the
  /// last page read ends. A question removed, or no longer shared, goes; one
  /// shared since comes in at the top; and the student keeps their place.
  ///
  /// Quiet: no spinner, and a failure leaves the list as it was. It is
  /// ignored while a page is on its way, and its answer is dropped if other
  /// rows came in meanwhile. A next page asked for meanwhile, from the old
  /// cursor, is dropped in turn once the rows are swapped.
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

    final SharedQuestionsPage rows;
    try {
      rows = await _readFirstRows(
        opened is SharedQuestionsReady ? opened.questions.length : 0,
      );
    } catch (e) {
      AppLogger.info('Shared with me not refreshed: $e');
      return;
    }
    final current = state;
    if (!_showsSameRows(current, opened)) return;
    final refreshed = _firstPageState(rows);
    if (_showsSameRows(current, refreshed)) return;
    emit(refreshed);
  }

  /// The first [count] rows, or every row if there are fewer, read a whole
  /// page at a time from the first, as one page ending where the last page
  /// read ends. The first page is always read.
  Future<SharedQuestionsPage> _readFirstRows(int count) async {
    var page = await loadSharedQuestions();
    final questions = [...page.questions];
    while (questions.length < count &&
        page.nextCursor != null &&
        page.questions.isNotEmpty) {
      page = await loadSharedQuestions(cursor: page.nextCursor);
      questions.addAll(page.questions);
    }
    return SharedQuestionsPage(
      questions: questions,
      nextCursor: page.nextCursor,
    );
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

  /// Adds the next page below the rows. If a refresh swapped the rows while
  /// the page was on its way, the page, which continues the old rows, is
  /// dropped.
  Future<void> _loadNextPage(
    SharedQuestionsReady current,
    Emitter<SharedQuestionsState> emit,
  ) async {
    final loading =
        current.copyWith(isLoadingMore: true, loadMoreFailed: false);
    emit(loading);
    try {
      final page = await loadSharedQuestions(cursor: current.nextCursor);
      if (state != loading) return;
      emit(SharedQuestionsReady(
        questions: [...current.questions, ...page.questions],
        nextCursor: page.nextCursor,
      ));
    } on Failure catch (f, stackTrace) {
      AppLogger.error('More of Shared with me failed to load',
          error: f, stackTrace: stackTrace);
      if (state != loading) return;
      emit(current.copyWith(isLoadingMore: false, loadMoreFailed: true));
    } catch (e, stackTrace) {
      AppLogger.error('More of Shared with me failed unexpectedly',
          error: e, stackTrace: stackTrace);
      if (state != loading) return;
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

  /// Whether [a] and [b] show the same rows, ending at the same cursor,
  /// whatever the next page is doing.
  static bool _showsSameRows(SharedQuestionsState a, SharedQuestionsState b) =>
      a is SharedQuestionsReady && b is SharedQuestionsReady
          ? a.copyWith(isLoadingMore: false, loadMoreFailed: false) ==
              b.copyWith(isLoadingMore: false, loadMoreFailed: false)
          : a == b;
}
