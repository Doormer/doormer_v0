import 'package:flutter/foundation.dart';

/// One request waiting on Profile.
class FriendRequestRowParams {
  /// The sender's.
  final String nickname;

  /// The sender's picture. Null when they have none.
  final String? artUrl;

  /// An answer, or a Block, is on its way.
  final bool isBusy;

  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onBlock;
  final VoidCallback onReport;

  const FriendRequestRowParams({
    required this.nickname,
    required this.artUrl,
    required this.isBusy,
    required this.onAccept,
    required this.onDecline,
    required this.onBlock,
    required this.onReport,
  });
}
