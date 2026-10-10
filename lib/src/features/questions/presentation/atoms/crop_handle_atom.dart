import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:flutter/material.dart';

/// One corner handle of the crop box: a small dot inside a touch target big
/// enough for a thumb.
///
/// Sizes are plain logical pixels, not ScreenUtil, because the editor places
/// the handles by them.
class CropHandleAtom extends StatelessWidget {
  static const double touchSize = 44;
  static const double _dotSize = 20;

  const CropHandleAtom({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: touchSize,
      child: Center(
        child: Container(
          width: _dotSize,
          height: _dotSize,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: context.colorScheme.primary, width: 3),
          ),
        ),
      ),
    );
  }
}
