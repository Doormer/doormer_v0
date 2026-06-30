import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/features/questions/presentation/molecules/ask_by_photo_header_molecule.dart';
import 'package:doormer/src/features/questions/presentation/organisms/photo_upload_panel_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solve_status_panel_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/photo_upload_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solve_status_panel_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';

class AskByPhotoTemplate extends StatelessWidget {
  final PhotoUploadPanelParams uploadParams;
  final SolveStatusPanelParams statusParams;

  const AskByPhotoTemplate({
    super.key,
    required this.uploadParams,
    required this.statusParams,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6E3FD7),
      body: SafeArea(
        child: Stack(
  children: [
    Positioned(
      top: 60.h,
      right: -30.w,
      child: Opacity(
        opacity: 0.12,
        child: Image.asset(
          'assets/images/starter_bg_person.png',
          width: 240.w,
        ),
      ),
    ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AskByPhotoHeaderMolecule(),
                  SizedBox(height: 24.h),
                  AppButtonAtom(
                    label: 'UPLOAD & SOLVE',
                    icon: Icons.camera_alt,
                    onPressed: uploadParams.isLoading
                        ? null
                        : uploadParams.onPickPhoto,
                  ),
                ],
              ),
            ),

            Positioned(
              left: 20.w,
              right: 20.w,
              bottom: 20.h,
              child: Container(
                height: 74.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF9B7BDD),
                  borderRadius: BorderRadius.circular(40.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    Icon(Icons.copy, size: 30, color: Colors.black),
                    Icon(Icons.smart_toy_outlined, size: 30, color: Colors.black),
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 36,
                      color: Color(0xE6B4EF2B),
                    ),
                    Icon(Icons.chat_bubble_outline, size: 30, color: Colors.black),
                    Icon(Icons.person_outline, size: 32, color: Colors.black),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}