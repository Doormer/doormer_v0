import 'package:flutter/foundation.dart';

class BottomActionBarParams {
  final VoidCallback onCopy;
  final VoidCallback onAiChat;
  final VoidCallback onUpload;
  final VoidCallback onChat;
  final VoidCallback onProfile;

  const BottomActionBarParams({
    required this.onCopy,
    required this.onAiChat,
    required this.onUpload,
    required this.onChat,
    required this.onProfile,
  });
}
