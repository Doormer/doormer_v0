import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AskByPhotoHeaderMolecule extends StatelessWidget {
  const AskByPhotoHeaderMolecule({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ask Scarlet a question by photo',
          style: AppTextStyles.displayMedium.copyWith(fontSize: 32.sp),
        ),
        SizedBox(height: 8.h),
        Text(
          'Snap or upload a clear JPEG or PNG question. We will sort it into solved, unreadable, not-a-question, or timeout.',
          style: AppTextStyles.bodyLarge.copyWith(fontSize: 16.sp),
        ),
      ],
    );
  }
}
