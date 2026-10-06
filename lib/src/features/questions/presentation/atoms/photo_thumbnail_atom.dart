import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Builds the image for a photo link. Tests swap in images that load or fail.
typedef PhotoImageProviderBuilder = ImageProvider Function(String url);

ImageProvider networkPhotoImageProvider(String url) => NetworkImage(url);

/// A square crop of the student's photo, for spotting a question by its shape.
/// With no link, or a photo that will not load, it shows a plain tile with an
/// image icon instead.
class PhotoThumbnailAtom extends StatelessWidget {
  /// Null when the question has no thumbnail.
  final String? url;
  final double size;
  final PhotoImageProviderBuilder imageProviderBuilder;

  const PhotoThumbnailAtom({
    super.key,
    required this.url,
    required this.size,
    this.imageProviderBuilder = networkPhotoImageProvider,
  });

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: SizedBox.square(
        dimension: size,
        child: url == null
            ? _PlainTile(size: size)
            : Image(
                image: imageProviderBuilder(url),
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (frame != null || wasSynchronouslyLoaded) return child;
                  return const ColoredBox(color: QuestPalette.card);
                },
                errorBuilder: (context, error, stackTrace) =>
                    _PlainTile(size: size),
              ),
      ),
    );
  }
}

class _PlainTile extends StatelessWidget {
  final double size;

  const _PlainTile({required this.size});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('photo_thumbnail_fallback'),
      color: QuestPalette.card,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: size * 0.4,
          color: QuestPalette.muted,
        ),
      ),
    );
  }
}
