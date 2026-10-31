import 'package:flutter/foundation.dart';

/// The student's own friend code, and what they can do with it.
class FriendCodeParams {
  /// With its dash, such as `K7QM-2XPA`.
  final String friendCode;

  /// A new code is on its way.
  final bool isResetting;

  final VoidCallback onCopyCode;
  final VoidCallback onCopyInviteLink;

  /// Warns first that the old code and its invite links will stop working.
  final VoidCallback onResetCode;

  const FriendCodeParams({
    required this.friendCode,
    required this.isResetting,
    required this.onCopyCode,
    required this.onCopyInviteLink,
    required this.onResetCode,
  });
}
