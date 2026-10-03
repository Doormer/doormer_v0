import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/atoms/quest_ghost_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The reader before it has anything to read: still loading, or unable to.
///
/// It owns a Scaffold like the reader itself, so arriving at a solution does
/// not flash a bare white page first.
class SolutionReaderPlaceholderTemplate extends StatelessWidget {
  /// Null while loading. When set, this is shown instead of the spinner.
  final String? message;

  /// Optional recovery action shown only for an error message.
  final VoidCallback? onBack;

  const SolutionReaderPlaceholderTemplate({
    super.key,
    this.message,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    final onBack = this.onBack;

    return Scaffold(
      body: Center(
        child: message == null
            ? const CircularProgressIndicator(color: QuestPalette.violet)
            : Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      key: const Key('solution_reader_message'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: kDisplayFont,
                        fontSize: 15.sp,
                        height: 1.5,
                        color: QuestPalette.cream,
                      ),
                    ),
                    if (onBack != null) ...[
                      SizedBox(height: 18.h),
                      QuestGhostButtonAtom(
                        label: 'Back to Solve',
                        icon: Icons.chevron_left_rounded,
                        enabled: true,
                        onPressed: onBack,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
