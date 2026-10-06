import 'package:flutter/foundation.dart';

import 'saved_question_row_params.dart';

/// What fills the Saved page above the nav bar.
sealed class SavedQuestionsBodyParams {
  const SavedQuestionsBodyParams();
}

/// The first page is on its way.
class SavedQuestionsLoadingParams extends SavedQuestionsBodyParams {
  const SavedQuestionsLoadingParams();
}

/// The student has no solved questions yet.
class SavedQuestionsEmptyParams extends SavedQuestionsBodyParams {
  /// Goes to Solve.
  final VoidCallback onSolve;

  const SavedQuestionsEmptyParams({required this.onSolve});
}

/// The first page could not load.
class SavedQuestionsErrorParams extends SavedQuestionsBodyParams {
  final String message;
  final VoidCallback onRetry;

  const SavedQuestionsErrorParams({
    required this.message,
    required this.onRetry,
  });
}

/// The rows, and how loading the next page is going.
class SavedQuestionListParams extends SavedQuestionsBodyParams {
  final List<SavedQuestionRowParams> rows;

  /// Older questions remain to be loaded.
  final bool hasMore;
  final bool isLoadingMore;

  /// The last page failed to load and waits for Try again.
  final bool loadMoreFailed;

  final VoidCallback onLoadMore;
  final VoidCallback onRetryLoadMore;

  const SavedQuestionListParams({
    required this.rows,
    required this.hasMore,
    required this.isLoadingMore,
    required this.loadMoreFailed,
    required this.onLoadMore,
    required this.onRetryLoadMore,
  });
}
