import 'package:doormer/src/features/questions/presentation/molecules/ask_by_photo_header_molecule.dart';
import 'package:doormer/src/features/questions/presentation/molecules/solving_explanation_molecule.dart';
import 'package:doormer/src/features/questions/presentation/organisms/photo_upload_panel_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solve_status_panel_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solving_progress_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/photo_upload_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solve_status_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solving_view_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/display_ad_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/reveal_on_change_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/show_after_delay_atom.dart';
import 'package:doormer/src/shared/design/atomic/organisms/navigation_bar_organism.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';

class AskByPhotoTemplate extends StatelessWidget {
  /// How long a solve runs before the ad card appears. Shorter solves show
  /// no ad.
  static const Duration adDelay = Duration(seconds: 3);

  final PhotoUploadPanelParams uploadParams;
  final SolveStatusPanelParams statusParams;
  final NavigationBarParams navigationBarParams;

  /// Set while a photo is being solved. The solving view then replaces the
  /// heading and the photo panels.
  final SolvingViewParams? solving;

  const AskByPhotoTemplate({
    super.key,
    required this.uploadParams,
    required this.statusParams,
    required this.navigationBarParams,
    this.solving,
  });

  @override
  Widget build(BuildContext context) {
    final solving = this.solving;
    final hasPhoto = uploadParams.imageBytes != null;
    final isLoading = uploadParams.isLoading;

    // The solver panels stay hidden on the idle hero screen so the landing
    // state keeps the single-CTA design. They mount as soon as there is
    // something to act on: a picked photo, an in-flight solve, or a recoverable
    // failure. Without them onSubmit is unreachable and the solve flow dead-ends.
    //
    // The upload panel normally needs bytes; the page may explicitly show the
    // empty panel after a refused pick so the preview resets to its placeholder,
    // or while a photo is being prepared.
    final showUploadPanel =
        hasPhoto || uploadParams.showWhenEmpty || uploadParams.isPreparing;
    final showStatusPanel = statusParams.content.showActions || isLoading;
    final showPanels = showUploadPanel || showStatusPanel;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (solving != null)
              Positioned.fill(child: _buildSolvingView(solving))
            else if (showPanels)
              Positioned.fill(
                child: _buildSolvePanels(showUploadPanel, showStatusPanel),
              )
            else
              _buildHero(),
            Positioned(
              left: 20.w,
              right: 20.w,
              bottom: 20.h,
              child: NavigationBarOrganism(params: navigationBarParams),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 120.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.7,
              child: Image.asset(
                'assets/images/starter_bg_person.png',
                height: 180.h,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 12.h),
            const AskByPhotoHeaderMolecule(),
            SizedBox(height: 24.h),
            AppButtonAtom(
              label: 'UPLOAD & SOLVE',
              icon: Icons.camera_alt,
              variant: AppButtonVariant.accent,
              onPressed: uploadParams.isLoading || uploadParams.isPreparing
                  ? null
                  : uploadParams.onPickPhoto,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolvingView(SolvingViewParams solving) {
    final adUnit = solving.adUnit;

    return SingleChildScrollView(
      // Bottom padding clears the pinned navigation bar.
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 120.h),
      // Top-aligned, with the ad card last: it appears and disappears without
      // moving anything above it, and an ad below the main content doesn't
      // count toward the Better Ads 30% ad-density limit.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SolvingProgressOrganism(params: solving.progress),
          SizedBox(height: 16.h),
          const SolvingExplanationMolecule(),
          if (adUnit != null) ...[
            SizedBox(height: 24.h),
            ShowAfterDelayAtom(
              delay: adDelay,
              child: DisplayAdAtom(unit: adUnit),
            ),
          ],
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
          if (showStatusPanel)
            RevealOnChangeAtom(
              trigger: statusParams.content.showActions
                  ? statusParams.content.title
                  : null,
              child: SolveStatusPanelOrganism(params: statusParams),
            ),
        ],
      ),
    );
  }
}
