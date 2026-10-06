import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/atoms/photo_thumbnail_atom.dart';
import 'package:doormer/src/features/questions/presentation/organisms/enlarge_sheet_organism.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The student's own photo at full size, so they can read the question before
/// opening its solution. A photo with no link, or one that will not load,
/// shows an image icon instead, and the sheet stays open to be closed.
class PhotoEnlargeOrganism extends StatelessWidget {
  /// Null when the photo's link could not be made.
  final String? photoUrl;
  final VoidCallback onClose;
  final PhotoImageProviderBuilder imageProviderBuilder;

  const PhotoEnlargeOrganism({
    super.key,
    required this.photoUrl,
    required this.onClose,
    this.imageProviderBuilder = networkPhotoImageProvider,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = this.photoUrl;
    return EnlargeSheetOrganism(
      onClose: onClose,
      child: photoUrl == null
          ? const _PhotoUnavailable()
          : Image(
              key: const Key('photo_enlarge_image'),
              image: imageProviderBuilder(photoUrl),
              fit: BoxFit.contain,
              semanticLabel: 'The photo of the question',
              errorBuilder: (context, error, stackTrace) =>
                  const _PhotoUnavailable(),
            ),
    );
  }
}

class _PhotoUnavailable extends StatelessWidget {
  const _PhotoUnavailable();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.image_outlined,
      key: const Key('photo_enlarge_unavailable'),
      size: 56.w,
      color: QuestPalette.muted,
      semanticLabel: 'The photo could not be shown',
    );
  }
}
