import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entity/report_reason.dart';
import '../params/report_sheet_params.dart';

/// Reports a student to the Doormer team: a reason, an optional note, then
/// thanks. It also points to help beyond the app, and offers Block. A report
/// on its own doesn't remove or block anyone.
class ReportSheetOrganism extends StatefulWidget {
  static final netsafe = Uri.parse('https://netsafe.org.nz');
  static final eSafety = Uri.parse('https://www.esafety.gov.au/report');

  static const maxNoteLength = 500;

  /// The reasons, in the order the sheet lists them.
  static const reasonLabels = {
    ReportReason.rudeNickname: 'Rude or hurtful nickname',
    ReportReason.bullying: 'Bullying or being mean',
    ReportReason.pretending: 'Pretending to be someone else',
    ReportReason.other: 'Something else',
  };

  final ReportSheetParams params;

  const ReportSheetOrganism({super.key, required this.params});

  @override
  State<ReportSheetOrganism> createState() => _ReportSheetOrganismState();
}

class _ReportSheetOrganismState extends State<ReportSheetOrganism> {
  final _note = TextEditingController();
  ReportReason? _reason;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _send() {
    final reason = _reason;
    if (reason == null) return;
    widget.params.onSend(reason, _note.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final params = widget.params;
    final bodyStyle = TextStyle(fontSize: 13.sp, color: QuestPalette.body);
    return Container(
      decoration: BoxDecoration(
        color: QuestPalette.ink,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      params.title,
                      style: TextStyle(
                        fontFamily: kDisplayFont,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: QuestPalette.cream,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('report_close'),
                    onPressed: params.onClose,
                    icon: const Icon(Icons.close),
                    color: QuestPalette.muted,
                    tooltip: 'Close',
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              if (params.isSent)
                Text(
                  'Thanks. The Doormer team will look at this.',
                  style: bodyStyle,
                )
              else ...[
                Text('Why are you reporting them?', style: bodyStyle),
                for (final MapEntry(key: reason, value: label)
                    in ReportSheetOrganism.reasonLabels.entries)
                  RadioListTile<ReportReason>(
                    value: reason,
                    groupValue: _reason,
                    onChanged: params.isSending
                        ? null
                        : (chosen) => setState(() => _reason = chosen),
                    title: Text(label, style: bodyStyle),
                    contentPadding: EdgeInsets.zero,
                  ),
                SizedBox(height: 8.h),
                TextField(
                  key: const Key('report_note'),
                  controller: _note,
                  enabled: !params.isSending,
                  maxLength: ReportSheetOrganism.maxNoteLength,
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(
                    labelText: 'Add a note (optional)',
                  ),
                ),
                SizedBox(height: 8.h),
                AppButtonAtom(
                  label: 'Send report',
                  expand: true,
                  isLoading: params.isSending,
                  onPressed: _reason == null ? null : _send,
                ),
              ],
              SizedBox(height: 20.h),
              Text(
                'Get help beyond Doormer:',
                style: TextStyle(fontSize: 12.sp, color: QuestPalette.muted),
              ),
              Wrap(
                spacing: 8.w,
                children: [
                  TextButton(
                    onPressed: () =>
                        params.onOpenLink(ReportSheetOrganism.netsafe),
                    child: const Text('Netsafe (New Zealand)'),
                  ),
                  TextButton(
                    onPressed: () =>
                        params.onOpenLink(ReportSheetOrganism.eSafety),
                    child: const Text('eSafety (Australia)'),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              AppButtonAtom(
                label: 'Block',
                variant: AppButtonVariant.outlined,
                expand: true,
                onPressed: params.isSending ? null : params.onBlock,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
