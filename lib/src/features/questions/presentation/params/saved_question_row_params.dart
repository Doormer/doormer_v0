import 'package:flutter/foundation.dart';

/// What one row of the Saved list shows, and what tapping it does.
class SavedQuestionRowParams {
  final String title;

  /// Empty when there is no second line to show.
  final String detail;

  /// The day the question was asked, or in Shared with me, the day it was
  /// shared: "Today", "3 Oct".
  final String dayLabel;

  /// Null when the question has no thumbnail.
  final String? thumbnailUrl;

  /// The friend who shared the question, in Shared with me. Null in Mine.
  final ({String nickname, String? artUrl})? sender;

  /// Opens the question's solution.
  final VoidCallback onOpen;

  /// Shows the full photo.
  final VoidCallback onEnlargePhoto;

  const SavedQuestionRowParams({
    required this.title,
    required this.detail,
    required this.dayLabel,
    required this.thumbnailUrl,
    this.sender,
    required this.onOpen,
    required this.onEnlargePhoto,
  });
}
