import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class QuestionSolutionHandoffPage extends StatelessWidget {
  final String questionId;
  final AskByPhotoSolved? solvedState;

  const QuestionSolutionHandoffPage({
    super.key,
    required this.questionId,
    required this.solvedState,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 520.w),
            child: Padding(
              padding: EdgeInsets.all(28.w),
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.borders),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solution ready',
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 22.sp),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Question ID: $questionId',
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 14.sp),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'The solved payload is attached to this route for the US-3 solution view. This screen does not render math.',
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 14.sp),
                    ),
                    if (solvedState != null) ...[
                      SizedBox(height: 12.h),
                      Text(
                        'Steps received: ${solvedState!.solution.steps.length}',
                        style:
                            AppTextStyles.bodySmall.copyWith(fontSize: 12.sp),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
