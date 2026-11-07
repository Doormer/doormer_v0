import 'package:flutter/foundation.dart';

/// What the line above the reader's buttons says about sharing, and what its
/// buttons do. The sample has no such line.
sealed class SolutionShareLineParams {
  const SolutionShareLineParams();
}

/// The student's own question: Share, and once it is shared, who with and
/// Stop sharing.
class OwnQuestionShareLineParams extends SolutionShareLineParams {
  /// "Shared with Sam, Alex". Empty while it is shared with no one.
  final String sharedWithLabel;

  /// Stop sharing is on its way.
  final bool isStopping;

  final VoidCallback onShare;

  /// Asks first, then stops sharing.
  final VoidCallback onStopSharing;

  const OwnQuestionShareLineParams({
    required this.sharedWithLabel,
    required this.isStopping,
    required this.onShare,
    required this.onStopSharing,
  });
}

/// A question a friend shared: who shared it, Remove and Report.
class FriendQuestionShareLineParams extends SolutionShareLineParams {
  /// "Shared by Sam".
  final String sharedByLabel;

  /// The friend's nickname, for their picture's first letter.
  final String nickname;

  /// The friend's picture's art. Null when they have none.
  final String? artUrl;

  /// Remove is on its way.
  final bool isRemoving;

  /// Asks first, then takes the question out of Shared with me.
  final VoidCallback onRemove;

  /// Opens the report sheet.
  final VoidCallback onReport;

  const FriendQuestionShareLineParams({
    required this.sharedByLabel,
    required this.nickname,
    required this.artUrl,
    required this.isRemoving,
    required this.onRemove,
    required this.onReport,
  });
}
