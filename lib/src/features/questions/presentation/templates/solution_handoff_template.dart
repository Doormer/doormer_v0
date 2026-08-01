import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/shared/design/atomic/atoms/surface_card_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SolutionHandoffTemplate extends StatelessWidget {
  final String questionId;
  final int? stepCount;

  const SolutionHandoffTemplate({
    super.key,
    required this.questionId,
    this.stepCount,
  });

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 520.w),
            child: Padding(
              padding: EdgeInsets.all(28.w),
              child: SurfaceCardAtom(
                padding: EdgeInsets.all(24.w),
                radius: 16.r,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solution ready',
                      style: tt.titleLarge?.copyWith(fontSize: 22.sp),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Question ID: $questionId',
                      style: tt.bodyMedium?.copyWith(fontSize: 14.sp),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'The solved payload is attached to this route for the US-3 solution view. This screen does not render math.',
                      style: tt.bodyMedium?.copyWith(fontSize: 14.sp),
                    ),
                    if (stepCount != null) ...[
                      SizedBox(height: 12.h),
                      Text(
                        'Steps received: $stepCount',
                        style: tt.bodySmall?.copyWith(fontSize: 12.sp),
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
