import 'package:flutter/widgets.dart';

import '../../domain/entity/draw_outcome.dart';

class RevealParams {
  final DrawOutcome outcome;

  /// The quiet line under the headline.
  ///
  /// The mockup gives every outcome one — deck progress for a new card, that
  /// the plain copy is kept for an upgrade, what a spare is worth for a
  /// duplicate. The headline says what happened; this says what it means.
  final String supportingLine;

  final VoidCallback onDismiss;

  const RevealParams({
    required this.outcome,
    required this.supportingLine,
    required this.onDismiss,
  });
}
