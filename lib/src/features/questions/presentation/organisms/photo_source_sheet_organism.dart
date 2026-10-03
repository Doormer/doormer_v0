import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PhotoSourceSheetOrganism extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onCancel;

  const PhotoSourceSheetOrganism({
    super.key,
    required this.onCamera,
    required this.onGallery,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add a photo', style: context.textTheme.titleMedium),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Open camera'),
              onTap: onCamera,
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: onGallery,
            ),
            SizedBox(height: 8.h),
            AppButtonAtom(
              label: 'Cancel',
              variant: AppButtonVariant.outlined,
              expand: true,
              onPressed: onCancel,
            ),
          ],
        ),
      ),
    );
  }
}
