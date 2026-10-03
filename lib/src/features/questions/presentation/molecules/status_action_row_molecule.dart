import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';

class StatusActionRowMolecule extends StatelessWidget {
  final VoidCallback onRetake;

  const StatusActionRowMolecule({
    super.key,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButtonAtom(label: 'Retake', onPressed: onRetake),
        ),
      ],
    );
  }
}
