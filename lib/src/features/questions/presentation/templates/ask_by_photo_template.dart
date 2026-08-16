import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/features/questions/presentation/molecules/ask_by_photo_header_molecule.dart';
import 'package:doormer/src/features/questions/presentation/organisms/navigation_bar_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/photo_upload_panel_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solve_status_panel_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/bottom_action_bar_params.dart';
import 'package:doormer/src/features/questions/presentation/params/photo_upload_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solve_status_panel_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';

class AskByPhotoTemplate extends StatelessWidget {
  final PhotoUploadPanelParams uploadParams;
  final SolveStatusPanelParams statusParams;
  final BottomActionBarParams bottomBarParams;

  const AskByPhotoTemplate({
    super.key,
    required this.uploadParams,
    required this.statusParams,
    required this.bottomBarParams,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = uploadParams.imageBytes != null;
    final isLoading = uploadParams.isLoading;

    // The solver panels stay hidden on the idle hero screen so the landing
    // state keeps the single-CTA design. They mount as soon as there is
    // something to act on: a picked photo, an in-flight solve, or a recoverable
    // failure. Without them onSubmit is unreachable and the solve flow dead-ends.
    //
    // The upload panel is gated on `hasPhoto` alone, never on `isLoading`: with
    // no bytes it renders a "choose a file" placeholder, which would contradict
    // the status panel claiming to solve that photo. The loading state carries
    // the photo, so `hasPhoto` stays true for the whole solve.
    final showUploadPanel = hasPhoto;
    final showStatusPanel = statusParams.content.showActions || isLoading;
    final showPanels = showUploadPanel || showStatusPanel;

    return Scaffold(
      backgroundColor: context.colorScheme.primary,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 60.h,
              right: -30.w,
              child: Opacity(
                opacity: 0.7,
                child: Image.asset(
                  'assets/images/starter_bg_person.png',
                  width: 240.w,
                ),
              ),
            ),
            if (showPanels)
              Positioned.fill(
                  child: _buildSolvePanels(showUploadPanel, showStatusPanel))
            else
              _buildHero(),
            Positioned(
              left: 20.w,
              right: 20.w,
              bottom: 20.h,
              child: NavigationBarOrganism(params: bottomBarParams),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AskByPhotoHeaderMolecule(),
          SizedBox(height: 24.h),
          AppButtonAtom(
            label: 'UPLOAD & SOLVE',
            icon: Icons.camera_alt,
            variant: AppButtonVariant.accent,
            onPressed: uploadParams.isLoading ? null : uploadParams.onPickPhoto,
          ),
        ],
      ),
    );
  }

  Widget _buildSolvePanels(bool showUploadPanel, bool showStatusPanel) {
    return SingleChildScrollView(
      // Bottom padding clears the pinned navigation bar.
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 120.h),
      child: Column(
        children: [
          const AskByPhotoHeaderMolecule(),
          SizedBox(height: 24.h),
          if (showUploadPanel) ...[
            PhotoUploadPanelOrganism(params: uploadParams),
            SizedBox(height: 16.h),
          ],
          if (showStatusPanel) SolveStatusPanelOrganism(params: statusParams),
        ],
      ),
    );
  }
}
