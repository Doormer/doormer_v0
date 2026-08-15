import 'package:flutter/material.dart';

typedef DiagramImageProviderBuilder = ImageProvider Function(String url);

ImageProvider networkDiagramImageProvider(String url) => NetworkImage(url);

/// One payload diagram, tone-corrected for the dark page.
class DiagramAtom extends StatelessWidget {
  /// `invert(1)` composed with `hue-rotate(180deg)`.
  ///
  /// The payload's PNGs are transparent line art authored for a light page.
  /// Unfiltered, the `#222222` rectangle sits at 1.09:1 against the dark
  /// surface — invisible. Inverting alone reaches 12:1 but turns the blue road
  /// edges orange and the purple label green, breaking the colour coding that
  /// ties each measurement label to its edge. The hue rotation puts the hues
  /// back, so only lightness flips.
  static const ColorFilter inkFilter = ColorFilter.matrix(<double>[
    0.574, -1.43, -0.144, 0.0, 255.0, //
    -0.426, -0.43, -0.144, 0.0, 255.0, //
    -0.426, -1.43, 0.856, 0.0, 255.0, //
    0.0, 0.0, 0.0, 1.0, 0.0, //
  ]);

  final String url;
  final double aspectRatio;
  final String semanticsLabel;
  final VoidCallback onFailed;
  final DiagramImageProviderBuilder imageProviderBuilder;

  const DiagramAtom({
    super.key,
    required this.url,
    required this.aspectRatio,
    required this.semanticsLabel,
    required this.onFailed,
    this.imageProviderBuilder = networkDiagramImageProvider,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ColorFiltered(
        colorFilter: inkFilter,
        child: Image(
          image: imageProviderBuilder(url),
          fit: BoxFit.contain,
          semanticLabel: semanticsLabel,
          errorBuilder: (context, error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onFailed());
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
