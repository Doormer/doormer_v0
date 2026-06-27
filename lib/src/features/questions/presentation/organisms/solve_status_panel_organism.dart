import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:doormer/src/features/questions/presentation/molecules/status_action_row_molecule.dart';
import 'package:doormer/src/features/questions/presentation/params/solve_status_panel_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/surface_card_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SolveStatusPanelOrganism extends StatelessWidget {
  final SolveStatusPanelParams params;

  const SolveStatusPanelOrganism({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    final content = params.content;

    return SurfaceCardAtom(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content.title,
            style: AppTextStyles.titleLarge.copyWith(fontSize: 20.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            content.body,
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 14.sp),
          ),
          if (content.showActions) ...[
            SizedBox(height: 20.h),
            StatusActionRowMolecule(
              onRetake: params.onRetake,
              onTypeInstead: params.onTypeInstead,
            ),
          ],
        ],
      ),
    );
  }
}
