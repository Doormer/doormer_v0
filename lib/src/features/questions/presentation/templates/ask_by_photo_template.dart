import 'package:doormer/src/features/questions/presentation/molecules/ask_by_photo_header_molecule.dart';
import 'package:doormer/src/features/questions/presentation/molecules/user_status_molecule.dart';
import 'package:doormer/src/features/questions/presentation/organisms/bottom_action_bar_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/bottom_action_bar_params.dart';
import 'package:doormer/src/features/questions/presentation/params/photo_upload_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solve_status_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/params/user_status_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';

class AskByPhotoTemplate extends StatelessWidget {
  final UserStatusParams userStatusParams;
  final PhotoUploadPanelParams uploadParams;
  final SolveStatusPanelParams statusParams;
  final BottomActionBarParams bottomBarParams;

  const AskByPhotoTemplate({
    super.key,
    required this.userStatusParams,
    required this.uploadParams,
    required this.statusParams,
    required this.bottomBarParams,
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
              child: UserStatusMolecule(params: userStatusParams),
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
              child: BottomActionBarOrganism(params: bottomBarParams),
            ),
          ],
        ),
      ),
    );
  }
}
