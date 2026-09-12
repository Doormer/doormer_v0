import 'package:doormer/src/features/questions/presentation/mapper/solve_status_presenter.dart';
import 'package:flutter/foundation.dart';

class SolveStatusPanelParams {
  final SolveStatusContent content;
  final VoidCallback onRetake;
  final VoidCallback onTypeInstead;

  const SolveStatusPanelParams({
    required this.content,
    required this.onRetake,
    required this.onTypeInstead,
  });
}
