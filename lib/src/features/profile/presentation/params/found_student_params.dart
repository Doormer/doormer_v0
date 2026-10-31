import 'package:flutter/foundation.dart';

/// The owner of a code just found, so the student can check it's the right
/// person, and what can be done next.
class FoundStudentParams {
  final String nickname;

  /// Null when they have no picture.
  final String? artUrl;

  /// How the two are connected, such as "Request sent". Null when there's
  /// nothing to say.
  final String? status;

  /// The button's label, such as "Send request". Null when there's nothing
  /// to do.
  final String? actionLabel;

  final VoidCallback? onAction;

  /// The button's action is on its way.
  final bool isActing;

  const FoundStudentParams({
    required this.nickname,
    required this.artUrl,
    required this.status,
    required this.actionLabel,
    required this.onAction,
    required this.isActing,
  });
}
