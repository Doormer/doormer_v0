import 'package:doormer/src/core/ads/display_ad_unit.dart';
import 'package:flutter/widgets.dart';

/// Ads run only on the web, where Google's ad code can.
const bool displayAdsSupported = false;

/// Off the web there is no ad code to run, so this shows nothing.
class DisplayAdView extends StatelessWidget {
  final DisplayAdUnit unit;
  final VoidCallback onNoAd;

  const DisplayAdView({super.key, required this.unit, required this.onNoAd});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
