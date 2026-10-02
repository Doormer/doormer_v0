import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Why something could not load, with a Retry button under it.
class ErrorWithRetryMolecule extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorWithRetryMolecule({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: QuestPalette.muted),
          ),
          SizedBox(height: 14.h),
          AppButtonAtom(label: 'Retry', onPressed: onRetry),
        ],
      ),
    );
  }
}
