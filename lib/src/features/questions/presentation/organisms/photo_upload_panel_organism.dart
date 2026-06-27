import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:doormer/src/features/questions/presentation/molecules/photo_action_row_molecule.dart';
import 'package:doormer/src/features/questions/presentation/molecules/photo_preview_molecule.dart';
import 'package:doormer/src/features/questions/presentation/params/photo_upload_panel_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/surface_card_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PhotoUploadPanelOrganism extends StatelessWidget {
  final PhotoUploadPanelParams params;

  const PhotoUploadPanelOrganism({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = params.imageBytes != null;
    final name = params.fileName;

    return SurfaceCardAtom(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photo input',
            style: AppTextStyles.titleLarge.copyWith(fontSize: 20.sp),
          ),
          SizedBox(height: 16.h),
          PhotoPreviewMolecule(imageBytes: params.imageBytes),
          if (hasPhoto && name != null) ...[
            SizedBox(height: 12.h),
            Text(
              name,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 12.sp),
            ),
          ],
          SizedBox(height: 22.h),
          PhotoActionRowMolecule(
            hasPhoto: hasPhoto,
            isLoading: params.isLoading,
            onPick: params.onPickPhoto,
            onClear: params.onClear,
          ),
          SizedBox(height: 12.h),
          AppButtonAtom(
            label: 'Submit to solver',
            variant: AppButtonVariant.accent,
            expand: true,
            isLoading: params.isLoading,
            onPressed: hasPhoto && !params.isLoading ? params.onSubmit : null,
          ),
        ],
      ),
    );
  }
}
