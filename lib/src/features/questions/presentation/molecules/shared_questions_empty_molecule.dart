import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared with me before any friend has shared a question.
class SharedQuestionsEmptyMolecule extends StatelessWidget {
  const SharedQuestionsEmptyMolecule({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_outlined, size: 40.w, color: QuestPalette.muted),
          SizedBox(height: 12.h),
          Text(
            'Nothing shared yet. When a friend sends you a question, it '
            'shows here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.5,
              color: QuestPalette.body,
            ),
          ),
        ],
      ),
    );
  }
}
