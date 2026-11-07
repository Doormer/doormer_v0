import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Builds the image for a photo link. Tests swap in images that load or fail.
typedef PhotoImageProviderBuilder = ImageProvider Function(String url);

ImageProvider networkPhotoImageProvider(String url) => NetworkImage(url);

/// The student's photo, small, for spotting a question at a glance. The API
/// makes every thumbnail 3:2 with the whole question fitted in, so the frame
/// has that shape too; a thumbnail of another shape is shown whole, not cut.
/// With no link, or a photo that will not load, it shows a plain tile with an
/// image icon instead. Given a new link to the same photo, as the API signs
/// one afresh on every read, it keeps the photo on show until the new link
/// loads. Given a link to another photo, it starts blank.
class PhotoThumbnailAtom extends StatelessWidget {
  /// The frame's width for each point of its height.
  static const double aspectRatio = 3 / 2;

  /// Null when the question has no thumbnail.
  final String? url;
  final double height;
  final PhotoImageProviderBuilder imageProviderBuilder;

  const PhotoThumbnailAtom({
    super.key,
    required this.url,
    required this.height,
    this.imageProviderBuilder = networkPhotoImageProvider,
  });

  /// The photo a link reaches: the link without its query, which holds the
  /// signature that changes each time the link is signed.
  static String _photoOf(String url) => url.split('?').first;

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    final iconSize = height * 0.4;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: SizedBox(
        width: height * aspectRatio,
        height: height,
        child: url == null
            ? _PlainTile(iconSize: iconSize)
            : ColoredBox(
                color: QuestPalette.card,
                child: Image(
                  key: ValueKey(_photoOf(url)),
                  image: imageProviderBuilder(url),
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) =>
                      _PlainTile(iconSize: iconSize),
                ),
              ),
      ),
    );
  }
}

class _PlainTile extends StatelessWidget {
  final double iconSize;

  const _PlainTile({required this.iconSize});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('photo_thumbnail_fallback'),
      color: QuestPalette.card,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: iconSize,
          color: QuestPalette.muted,
        ),
      ),
    );
  }
}
