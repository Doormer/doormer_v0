import 'package:flutter/foundation.dart';

/// The student as friends see them, with their friend code.
class ProfileHeaderParams {
  final String nickname;

  /// Null when the student has no picture.
  final String? artUrl;

  /// With its dash, such as `K7QM-2XPA`.
  final String friendCode;

  final VoidCallback onEdit;

  const ProfileHeaderParams({
    required this.nickname,
    required this.artUrl,
    required this.friendCode,
    required this.onEdit,
  });
}
