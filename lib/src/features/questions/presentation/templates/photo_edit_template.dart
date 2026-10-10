import 'package:doormer/src/features/questions/presentation/molecules/photo_edit_toolbar_molecule.dart';
import 'package:doormer/src/features/questions/presentation/organisms/photo_crop_editor_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/photo_edit_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The crop & rotate screen: the photo with its crop box, the turn tools,
/// and Use photo.
///
/// Black, like the camera screen, so nothing around the photo changes how it
/// reads.
class PhotoEditTemplate extends StatelessWidget {
  final PhotoEditParams params;

  const PhotoEditTemplate({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Cancel',
          icon: const Icon(Icons.close),
          onPressed: params.onCancel,
        ),
        title: const Text('Crop & rotate'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          child: Column(
            children: [
              Text(
                'Drag the corners so only the question is inside the box.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white70, fontSize: 14.sp),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: PhotoCropEditorOrganism(
                  imageBytes: params.imageBytes,
                  imageSize: params.imageSize,
                  edit: params.edit,
                  onChanged: params.onEditChanged,
                ),
              ),
              SizedBox(height: 12.h),
              PhotoEditToolbarMolecule(
                onTurnLeft: params.onTurnLeft,
                onTurnRight: params.onTurnRight,
                onReset: params.onReset,
                color: Colors.white,
              ),
              SizedBox(height: 12.h),
              AppButtonAtom(
                label: 'Use photo',
                variant: AppButtonVariant.accent,
                expand: true,
                onPressed: params.onUsePhoto,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
