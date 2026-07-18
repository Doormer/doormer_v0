import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:doormer/src/features/questions/presentation/params/user_status_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserStatusMolecule extends StatelessWidget {
  final UserStatusParams params;

  const UserStatusMolecule({
    super.key,
    required this.params,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240.w,
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 14.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.userStatusSurface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.userStatusAvatarPlaceholder,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  params.levelLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onPrimary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Characters collected: '
                  '${params.collectedCount}/${params.totalCount}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onPrimary,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
