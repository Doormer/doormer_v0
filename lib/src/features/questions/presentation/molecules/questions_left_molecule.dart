import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One line about today's questions: how many are left or, with none left,
/// when they come back. It sits under Add a photo on the empty screen, and
/// at the top of the photo screen, above the photo. It changes only when the
/// count is read again, never on a timer. Screen readers announce the line
/// when it appears and when it changes.
class QuestionsLeftMolecule extends StatelessWidget {
  final String text;

  /// None left today. The line then says why no new photo can be sent, so it
  /// stands out.
  final bool isReached;

  const QuestionsLeftMolecule({
    super.key,
    required this.text,
    required this.isReached,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: kBodyFont,
          color: context.colorScheme.onSurface,
          fontSize: 15.sp,
          fontWeight: isReached ? FontWeight.w700 : FontWeight.w500,
          height: 1.3,
        ),
      ),
    );
  }
}
