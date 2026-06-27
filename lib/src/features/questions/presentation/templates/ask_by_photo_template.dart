import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/features/questions/presentation/molecules/ask_by_photo_header_molecule.dart';
import 'package:doormer/src/features/questions/presentation/organisms/photo_upload_panel_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solve_status_panel_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/photo_upload_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solve_status_panel_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 32.h),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 980.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AskByPhotoHeaderMolecule(),
                  SizedBox(height: 28.h),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 720.w;
                      final uploadPanel =
                          PhotoUploadPanelOrganism(params: uploadParams);
                      final statusPanel =
                          SolveStatusPanelOrganism(params: statusParams);

                      if (!isWide) {
                        return Column(
                          children: [
                            uploadPanel,
                            SizedBox(height: 20.h),
                            statusPanel,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: uploadPanel),
                          SizedBox(width: 24.w),
                          Expanded(flex: 4, child: statusPanel),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
