import 'package:flutter/widgets.dart';

import '../../domain/entity/draw_outcome.dart';

class RevealParams {
  final DrawOutcome outcome;
  final VoidCallback onDismiss;

  const RevealParams({required this.outcome, required this.onDismiss});
}
