import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AskByPhotoHeaderMolecule extends StatelessWidget {
  const AskByPhotoHeaderMolecule({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = context.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Snap it. Solve it.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kDisplayFont,
            color: onSurface,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          // Broken by hand so a phone never leaves "step." alone on a line.
          'Unlock the answer,\nstep by step.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kBodyFont,
            color: onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}
