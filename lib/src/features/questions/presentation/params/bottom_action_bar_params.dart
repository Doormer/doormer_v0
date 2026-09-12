import 'package:flutter/foundation.dart';

class BottomActionBarParams {
  final int selectedIndex;
  final VoidCallback onCopy;
  final VoidCallback onAiChat;
  final VoidCallback onUpload;
  final VoidCallback onChat;
  final VoidCallback onProfile;

  const BottomActionBarParams({
    this.selectedIndex = 0,
    required this.onCopy,
    required this.onAiChat,
    required this.onUpload,
    required this.onChat,
    required this.onProfile,
  });
}
