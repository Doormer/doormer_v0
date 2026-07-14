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
Positioned(
  top: 24.h,
  left: 24.w,
  child: Container(
    width: 240.w,
    padding: EdgeInsets.symmetric(
      horizontal: 16.w,
      vertical: 14.h,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFF3B236B),
      borderRadius: BorderRadius.circular(12.r),
    ),
    child: Row(
      children: [
        Container(
          width: 34.w,
          height: 34.w,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFE8E8E8),
          ),
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LV.xx',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Characters collected: 12/50',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
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
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 30, color: Colors.black),
                      onPressed: (){
                        print('Cloc');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.smart_toy_outlined, size: 30, color: Colors.black),
                      onPressed: (){
                        print('AI chat');
                      }
                    ),
                    IconButton(
                      icon: const  Icon(
                      Icons.camera_alt_outlined,
                      size: 36,
                      color: Color(0xE6B4EF2B),
                    ),
                    onPressed:(){
                      print('Upload');
                      },
                    ),
          
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, size: 30, color: Colors.black),
                      onPressed: (){
                        print('chat');
                      }
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_outline, size: 32, color: Colors.black),
                      onPressed:(){
                        print('profile');
                      }
                      )
                    
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