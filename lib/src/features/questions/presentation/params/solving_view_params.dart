import 'package:doormer/src/core/ads/display_ad_unit.dart';
import 'package:doormer/src/features/questions/presentation/params/solving_progress_params.dart';
import 'package:flutter/foundation.dart';

/// Everything the screen shows while a photo is being solved.
class SolvingViewParams {
  final SolvingProgressParams progress;

  /// The ad shown once the solve has run for a while. Null when ads are off.
  final DisplayAdUnit? adUnit;

  /// Opens the explanation of why Doormer shows ads. Null when ads are off,
  /// which also hides the "Why ads?" link.
  final VoidCallback? onWhyAds;

  const SolvingViewParams({
    required this.progress,
    this.adUnit,
    this.onWhyAds,
  });
}
