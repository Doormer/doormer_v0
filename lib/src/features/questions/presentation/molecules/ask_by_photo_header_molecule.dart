import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AskByPhotoHeaderMolecule extends StatelessWidget {
  const AskByPhotoHeaderMolecule({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = context.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Ready to solve?',
          textAlign: TextAlign.center,
          style: GoogleFonts.josefinSans(
            color: onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          'Upload a photo',
          textAlign: TextAlign.center,
          style: GoogleFonts.josefinSans(
            color: onSurface,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          "We'll help you solve it step by step",
          textAlign: TextAlign.center,
          style: GoogleFonts.josefinSans(
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
