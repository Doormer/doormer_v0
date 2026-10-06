import 'package:doormer/src/core/ads/display_ad_unit.dart';
import 'package:doormer/src/features/questions/presentation/params/solving_progress_params.dart';

/// Everything the screen shows while a photo is being solved.
class SolvingViewParams {
  final SolvingProgressParams progress;

  /// A study tip, the same for the whole solve.
  final String tip;

  /// The ad shown once the solve has run for a while. Null when ads are off.
  final DisplayAdUnit? adUnit;

  const SolvingViewParams({
    required this.progress,
    required this.tip,
    this.adUnit,
  });
}
