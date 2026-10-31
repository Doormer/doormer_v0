import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One line under Solve's heading: the questions left today or, with none
/// left, when they come back. It changes only when the count is read again,
/// never on a timer.
class QuestionsLeftMolecule extends StatelessWidget {
  final String text;

  /// None left today. The line is then why nothing can be sent, so it stands
  /// out.
  final bool isReached;

  const QuestionsLeftMolecule({
    super.key,
    required this.text,
    required this.isReached,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: kBodyFont,
        color: context.colorScheme.onSurface,
        fontSize: 15.sp,
        fontWeight: isReached ? FontWeight.w700 : FontWeight.w500,
        height: 1.3,
      ),
    );
  }
}
