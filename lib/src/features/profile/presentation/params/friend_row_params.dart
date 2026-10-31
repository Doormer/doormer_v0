import 'package:flutter/foundation.dart';

/// One friend on Profile.
class FriendRowParams {
  final String nickname;

  /// Null when the friend has no picture.
  final String? artUrl;

  /// A Remove or Block is on its way.
  final bool isBusy;

  /// Opens the friend's collection.
  final VoidCallback onOpen;

  final VoidCallback onRemove;
  final VoidCallback onBlock;
  final VoidCallback onReport;

  const FriendRowParams({
    required this.nickname,
    required this.artUrl,
    required this.isBusy,
    required this.onOpen,
    required this.onRemove,
    required this.onBlock,
    required this.onReport,
  });
}
