import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/features/questions/presentation/atoms/elapsed_time_atom.dart';
import 'package:doormer/src/features/questions/presentation/params/solving_progress_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/surface_card_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The photo being solved, a spinner, how long it has been, and what to
/// expect.
class SolvingProgressOrganism extends StatelessWidget {
  final SolvingProgressParams params;

  const SolvingProgressOrganism({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colorScheme;
    final photo = params.imageBytes;
    final thumbnailSize = 56.r;

    return SurfaceCardAtom(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (photo != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: Image.memory(
                    photo,
                    width: thumbnailSize,
                    height: thumbnailSize,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) =>
                        SizedBox.square(dimension: thumbnailSize),
                  ),
                ),
                SizedBox(width: 14.w),
              ],
              SizedBox.square(
                dimension: 18.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: cs.tertiary,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  params.title,
                  style: tt.titleLarge?.copyWith(fontSize: 18.sp),
                ),
              ),
              SizedBox(width: 8.w),
              ElapsedTimeAtom(
                style: tt.titleSmall?.copyWith(
                  fontSize: 14.sp,
                  color: cs.onSurfaceVariant,
                  // Digits of equal width, so the counter doesn't jitter.
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(params.body, style: tt.bodyMedium?.copyWith(fontSize: 14.sp)),
        ],
      ),
    );
  }
}
