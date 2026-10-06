import 'package:flutter/foundation.dart';

/// What one row of the Saved list shows, and what tapping it does.
class SavedQuestionRowParams {
  final String title;

  /// Empty when there is no second line to show.
  final String detail;

  final String askedLabel;

  /// Null when the question has no thumbnail.
  final String? thumbnailUrl;

  /// Opens the question's solution.
  final VoidCallback onOpen;

  /// Shows the full photo.
  final VoidCallback onEnlargePhoto;

  const SavedQuestionRowParams({
    required this.title,
    required this.detail,
    required this.askedLabel,
    required this.thumbnailUrl,
    required this.onOpen,
    required this.onEnlargePhoto,
  });
}
