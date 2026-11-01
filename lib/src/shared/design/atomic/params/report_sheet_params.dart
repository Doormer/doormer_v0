import 'package:doormer/src/shared/friends/entity/report_reason.dart';
import 'package:flutter/foundation.dart';

/// What the report sheet shows, and what its buttons do.
class ReportSheetParams {
  /// Names the student being reported, such as "Report Sam".
  final String title;

  /// The report is on its way.
  final bool isSending;

  /// The report reached the team.
  final bool isSent;

  /// [note] is trimmed, and empty when the student wrote none. Null turns
  /// Send report off: the reader does while the question is being removed,
  /// since the removal ends the share the report would be about.
  final void Function(ReportReason reason, String note)? onSend;

  /// Blocks the student. Null offers no Block: the reader offers it only
  /// once a report about a shared question has reached the team, since a
  /// block ends the share the report is about, or once the report is
  /// refused in a way trying again won't fix.
  final VoidCallback? onBlock;

  final VoidCallback onClose;

  /// Opens a help service's site, outside the app.
  final void Function(Uri link) onOpenLink;

  const ReportSheetParams({
    required this.title,
    required this.isSending,
    required this.isSent,
    required this.onSend,
    this.onBlock,
    required this.onClose,
    required this.onOpenLink,
  });
}
