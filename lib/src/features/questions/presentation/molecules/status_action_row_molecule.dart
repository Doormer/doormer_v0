import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StatusActionRowMolecule extends StatelessWidget {
  /// Null when the photo is still on screen and the upload panel is already
  /// offering Retake directly beneath it.
  final VoidCallback? onRetake;
  final VoidCallback onTypeInstead;

  const StatusActionRowMolecule({
    super.key,
    this.onRetake,
    required this.onTypeInstead,
  });

  @override
  Widget build(BuildContext context) {
    final retake = onRetake;

    return Row(
      children: [
        if (retake != null) ...[
          Expanded(
            child: AppButtonAtom(label: 'Retake', onPressed: retake),
          ),
          SizedBox(width: 12.w),
        ],
        Expanded(
          child: AppButtonAtom(
            label: 'Type instead',
            // Stays secondary even when it is the only button here: the
            // primary action for a failure is up in the photo panel.
            variant: AppButtonVariant.outlined,
            onPressed: onTypeInstead,
          ),
        ),
      ],
    );
  }
}
