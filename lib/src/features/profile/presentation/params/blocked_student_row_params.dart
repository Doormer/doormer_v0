import 'package:flutter/foundation.dart';

/// One row of the Blocked list.
class BlockedStudentRowParams {
  final String nickname;

  /// Null when the student has no picture.
  final String? artUrl;

  /// The Unblock is on its way.
  final bool isUnblocking;

  final VoidCallback onUnblock;

  const BlockedStudentRowParams({
    required this.nickname,
    required this.artUrl,
    required this.isUnblocking,
    required this.onUnblock,
  });
}
