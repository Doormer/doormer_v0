import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The reader before it has anything to read: still loading, or unable to.
///
/// It owns a Scaffold in the same colours as the reader itself, so arriving at
/// a solution does not flash a bare white page first.
class SolutionReaderPlaceholderTemplate extends StatelessWidget {
  /// Null while loading. When set, this is shown instead of the spinner.
  final String? message;

  const SolutionReaderPlaceholderTemplate({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final message = this.message;

    return Scaffold(
      backgroundColor: QuestPalette.night,
      body: Center(
        child: message == null
            ? const CircularProgressIndicator(color: QuestPalette.violet)
            : Padding(
                padding: EdgeInsets.all(24.w),
                child: Text(
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
              ),
      ),
    );
  }
}
