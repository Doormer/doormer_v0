part of 'shared_questions_bloc.dart';

sealed class SharedQuestionsState extends Equatable {
  const SharedQuestionsState();

  @override
  List<Object?> get props => const [];
}

/// The first page is on its way.
class SharedQuestionsLoading extends SharedQuestionsState {
  const SharedQuestionsLoading();
}

/// No friend has shared a question with the student.
class SharedQuestionsEmpty extends SharedQuestionsState {
  const SharedQuestionsEmpty();
}

/// The first page could not load.
class SharedQuestionsError extends SharedQuestionsState {
  final String message;

  const SharedQuestionsError(this.message);

  @override
  List<Object?> get props => [message];
}

class SharedQuestionsReady extends SharedQuestionsState {
  /// Every row loaded so far, newest share first.
  final List<SharedQuestionSummary> questions;

  /// Where the next page starts, as the API gave it. Null once every row is
  /// loaded.
  final String? nextCursor;

  /// The next page is on its way.
  final bool isLoadingMore;

  /// The last request for the next page failed. The rows already loaded stay,
  /// and the list waits for Try again.
  final bool loadMoreFailed;

  const SharedQuestionsReady({
    required this.questions,
    this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  bool get hasMore => nextCursor != null;

  SharedQuestionsReady copyWith({bool? isLoadingMore, bool? loadMoreFailed}) {
    return SharedQuestionsReady(
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
