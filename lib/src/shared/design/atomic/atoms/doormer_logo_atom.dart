import 'package:flutter/material.dart';

/// The Doormer app icon: the question path, its levels and the door, on the
/// rounded night tile. `tool/generate_brand_icons.dart` makes the image from
/// the master icon.
///
/// Screen readers hear "Doormer". A page whose heading already names Doormer
/// can [excludeFromSemantics], so it isn't said twice.
class DoormerLogoAtom extends StatelessWidget {
  static const _assetName = 'assets/images/brand/doormer_icon.png';

  /// The side of the square, in logical pixels.
  final double size;

  final bool excludeFromSemantics;

  const DoormerLogoAtom({
    super.key,
    required this.size,
    this.excludeFromSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetName,
      width: size,
      height: size,
      semanticLabel: 'Doormer',
      excludeFromSemantics: excludeFromSemantics,
      filterQuality: FilterQuality.medium,
    );
  }
}
