import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The quarks just earned, in flight from the answer vault to the HUD balance.
class QuarkRewardAtom extends StatelessWidget {
  final String label;

  const QuarkRewardAtom({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: QuestPalette.amber,
        borderRadius: BorderRadius.circular(99.r),
        boxShadow: [
          BoxShadow(
            color: QuestPalette.amber.withValues(alpha: 0.9),
            blurRadius: 18,
            offset: const Offset(0, 8),
            spreadRadius: -7,
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: kDisplayFont,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: QuestPalette.onAmber,
          height: 1.2,
        ),
      ),
    );
  }
}
