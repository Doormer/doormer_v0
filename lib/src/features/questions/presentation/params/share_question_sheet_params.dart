import 'package:flutter/foundation.dart';

/// What the share sheet shows, and what its buttons do.
class ShareQuestionSheetParams {
  final ShareSheetBodyParams body;
  final VoidCallback onClose;

  const ShareQuestionSheetParams({required this.body, required this.onClose});
}

/// What fills the sheet below its heading and what friends will see.
sealed class ShareSheetBodyParams {
  const ShareSheetBodyParams();
}

/// The friends are on their way.
class ShareSheetLoadingParams extends ShareSheetBodyParams {
  const ShareSheetLoadingParams();
}

/// Why there is no one to tick, with Try again when trying again can help.
class ShareSheetMessageParams extends ShareSheetBodyParams {
  final String message;
  final VoidCallback? onRetry;

  const ShareSheetMessageParams({required this.message, this.onRetry});
}

/// A tick box for each friend, then Send.
class ShareSheetFriendsParams extends ShareSheetBodyParams {
  final List<ShareFriendRowParams> friends;

  /// As many friends are ticked as one send takes.
  final bool isFull;

  final bool isSending;

  /// Null while no friend is ticked, and while sending.
  final VoidCallback? onSend;

  const ShareSheetFriendsParams({
    required this.friends,
    required this.isFull,
    required this.isSending,
    required this.onSend,
  });
}

/// One friend in the sheet.
class ShareFriendRowParams {
  final String nickname;

  /// Their picture's art. Null when they have none.
  final String? artUrl;

  final bool isTicked;

  /// The question is already shared with them, so they stay ticked.
  final bool isShared;

  /// Null when the tick can't change: they already have the question, the
  /// sheet is full, or it is sending.
  final VoidCallback? onToggle;

  const ShareFriendRowParams({
    required this.nickname,
    required this.artUrl,
    required this.isTicked,
    required this.isShared,
    required this.onToggle,
  });
}
