import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The Saved page before the student has solved anything, with the way to
/// Solve.
class SavedQuestionsEmptyMolecule extends StatelessWidget {
  final VoidCallback onSolve;

  const SavedQuestionsEmptyMolecule({super.key, required this.onSolve});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_outline, size: 40.w, color: QuestPalette.muted),
          SizedBox(height: 12.h),
          Text(
            "No solved questions yet. Snap a photo and it'll be saved here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.5,
              color: QuestPalette.body,
            ),
          ),
          SizedBox(height: 18.h),
          AppButtonAtom(
            label: 'Solve a question',
            icon: Icons.camera_alt,
            variant: AppButtonVariant.accent,
            onPressed: onSolve,
          ),
        ],
      ),
    );
  }
}
