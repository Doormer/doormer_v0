import 'package:flutter/foundation.dart';

import 'found_student_params.dart';
import 'friend_code_params.dart';

/// What fills Add a friend under its heading.
sealed class AddFriendBodyParams {
  const AddFriendBodyParams();
}

class AddFriendLoadingParams extends AddFriendBodyParams {
  const AddFriendLoadingParams();
}

/// Why the page can't be used, with Try again when trying again can help.
class AddFriendMessageParams extends AddFriendBodyParams {
  final String message;
  final VoidCallback? onRetry;

  const AddFriendMessageParams({required this.message, this.onRetry});
}

/// The student's own code, the box to type a friend's code, and what the
/// last find found.
class AddFriendFormParams extends AddFriendBodyParams {
  final FriendCodeParams yourCode;

  /// What the box starts with: an invite's code, or nothing.
  final String initialCode;

  final bool isFinding;

  /// Takes the code as typed.
  final ValueChanged<String> onFind;

  /// Why the last find found no one. Null otherwise.
  final String? findMessage;

  /// Null before a find, and when it found no one.
  final FoundStudentParams? found;

  const AddFriendFormParams({
    required this.yourCode,
    required this.initialCode,
    required this.isFinding,
    required this.onFind,
    required this.findMessage,
    required this.found,
  });
}
