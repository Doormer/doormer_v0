part of 'saved_questions_bloc.dart';

sealed class SavedQuestionsState extends Equatable {
  const SavedQuestionsState();

  @override
  List<Object?> get props => const [];
}

/// The first page is on its way.
class SavedQuestionsLoading extends SavedQuestionsState {
  const SavedQuestionsLoading();
}

/// The student has no solved questions yet.
class SavedQuestionsEmpty extends SavedQuestionsState {
  const SavedQuestionsEmpty();
}

/// The first page could not load.
class SavedQuestionsError extends SavedQuestionsState {
  final String message;

  const SavedQuestionsError(this.message);

  @override
  List<Object?> get props => [message];
}

class SavedQuestionsReady extends SavedQuestionsState {
  /// Every row loaded so far, newest first.
  final List<SolvedQuestionSummary> questions;

  /// Where the next page starts. Null once every row is loaded.
  final String? nextCursor;

  /// The next page is on its way.
  final bool isLoadingMore;

  /// The last request for the next page failed. The rows already loaded stay,
  /// and the page waits for Try again.
  final bool loadMoreFailed;

  const SavedQuestionsReady({
    required this.questions,
    this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  bool get hasMore => nextCursor != null;

  SavedQuestionsReady copyWith({bool? isLoadingMore, bool? loadMoreFailed}) {
    return SavedQuestionsReady(
      questions: questions,
      nextCursor: nextCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }

  @override
  List<Object?> get props =>
      [questions, nextCursor, isLoadingMore, loadMoreFailed];
}
