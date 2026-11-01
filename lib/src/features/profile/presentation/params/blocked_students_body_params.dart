import 'package:flutter/foundation.dart';

import 'blocked_student_row_params.dart';

/// What fills the Blocked page under its heading.
sealed class BlockedStudentsBodyParams {
  const BlockedStudentsBodyParams();
}

class BlockedStudentsLoadingParams extends BlockedStudentsBodyParams {
  const BlockedStudentsLoadingParams();
}

class BlockedStudentsErrorParams extends BlockedStudentsBodyParams {
  final String message;
  final VoidCallback onRetry;

  const BlockedStudentsErrorParams({
    required this.message,
    required this.onRetry,
  });
}

/// The rows. None when the student has blocked no one.
class BlockedStudentListParams extends BlockedStudentsBodyParams {
  final List<BlockedStudentRowParams> rows;

  const BlockedStudentListParams({required this.rows});
}
