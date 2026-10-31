import 'package:flutter/foundation.dart';

import '../../domain/entity/report_reason.dart';

/// What the report sheet shows, and what its buttons do.
class ReportSheetParams {
  /// Names the student being reported, such as "Report Sam".
  final String title;

  /// The report is on its way.
  final bool isSending;

  /// The report reached the team.
  final bool isSent;

  /// [note] is trimmed, and empty when the student wrote none.
  final void Function(ReportReason reason, String note) onSend;

  final VoidCallback onBlock;
  final VoidCallback onClose;

  /// Opens a help service's site, outside the app.
  final void Function(Uri link) onOpenLink;

  const ReportSheetParams({
    required this.title,
    required this.isSending,
    required this.isSent,
    required this.onSend,
    required this.onBlock,
    required this.onClose,
    required this.onOpenLink,
  });
}
