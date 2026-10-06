import 'package:doormer/src/core/ads/display_ad_unit.dart';
import 'package:doormer/src/core/ads/display_ad_view.dart';
import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Builds the box Google's ad is drawn in. Tests swap in a stand-in.
typedef DisplayAdViewBuilder = Widget Function(
  DisplayAdUnit unit,
  VoidCallback onNoAd,
);

Widget _buildDisplayAdView(DisplayAdUnit unit, VoidCallback onNoAd) =>
    DisplayAdView(unit: unit, onNoAd: onNoAd);

/// One Google display ad under its label.
///
/// The label is part of the atom so no screen can show an unlabelled ad.
/// Google allows only "Advertisements" or "Sponsored Links".
///
/// Shows nothing where ads can't run, where there is less room than the ad
/// needs, or once Google has no ad. Once hidden it stays hidden, so it never
/// asks for a second ad.
class DisplayAdAtom extends StatefulWidget {
  static const String label = 'Advertisements';

  final DisplayAdUnit unit;

  /// Whether ads can run here. Only the web can.
  final bool supported;

  final DisplayAdViewBuilder buildAdView;

  const DisplayAdAtom({
    super.key,
    required this.unit,
    this.supported = displayAdsSupported,
    this.buildAdView = _buildDisplayAdView,
  });

  @override
  State<DisplayAdAtom> createState() => _DisplayAdAtomState();
}

class _DisplayAdAtomState extends State<DisplayAdAtom> {
  /// The ad has been on screen, so its one ad request has been made.
  bool _shown = false;

  /// Hidden for good: Google had no ad, or the ad lost its room after showing.
  bool _gone = false;

  void _onNoAd() {
    if (!mounted) return;
    setState(() => _gone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.supported) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_gone) return const SizedBox.shrink();
        if (constraints.maxWidth < DisplayAdUnit.width) {
          // Showing it again once there is room would ask for a second ad,
          // which Google counts as refreshing it.
          if (_shown) _gone = true;
          return const SizedBox.shrink();
        }
        _shown = true;

        return Center(
          child: SizedBox(
            width: DisplayAdUnit.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DisplayAdAtom.label,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontSize: 11.sp,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 6.h),
                SizedBox(
                  width: DisplayAdUnit.width,
                  height: DisplayAdUnit.height,
                  child: widget.buildAdView(widget.unit, _onNoAd),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
