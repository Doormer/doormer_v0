import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Turn left, Turn right and Reset, under the photo being cropped.
class PhotoEditToolbarMolecule extends StatelessWidget {
  final VoidCallback onTurnLeft;
  final VoidCallback onTurnRight;

  /// Null when the photo is already whole and unturned.
  final VoidCallback? onReset;

  /// Ink for the icons and the label; the crop screen is dark.
  final Color color;

  const PhotoEditToolbarMolecule({
    super.key,
    required this.onTurnLeft,
    required this.onTurnRight,
    required this.onReset,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Turn left',
          color: color,
          icon: const Icon(Icons.rotate_left),
          onPressed: onTurnLeft,
        ),
        SizedBox(width: 8.w),
        IconButton(
          tooltip: 'Turn right',
          color: color,
          icon: const Icon(Icons.rotate_right),
          onPressed: onTurnRight,
        ),
        SizedBox(width: 8.w),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: color),
          onPressed: onReset,
          child: const Text('Reset'),
        ),
      ],
    );
  }
}
