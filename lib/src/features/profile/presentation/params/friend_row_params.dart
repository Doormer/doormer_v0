import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:flutter/foundation.dart';

/// One friend on Profile.
class FriendRowParams {
  final String nickname;

  /// Null when the friend has no picture.
  final String? artUrl;

  /// The friend's level, drawn small after the nickname. Null below level
  /// 1: a friend at level 0 shows no icons.
  final Level? level;

  /// What screen readers hear for the nickname and the icons after it, such
  /// as `Sam, level 6`. Null reads the nickname alone.
  final String? semanticsLabel;

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
    this.level,
    this.semanticsLabel,
    required this.isBusy,
    required this.onOpen,
    required this.onRemove,
    required this.onBlock,
    required this.onReport,
  });
}
