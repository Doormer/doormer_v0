import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Tuning for [ResponsiveAppShell].
abstract final class AppLayout {
  /// The canvas every screen in this app is drawn against. Sizes written as
  /// `16.w` / `14.sp` / `24.h` mean "16, 14, 24 logical pixels on a 360x690
  /// phone", and the shell scales them from there.
  static const Size designSize = Size(360, 690);

  /// Widest the app column is allowed to grow before it stops stretching and
  /// centres itself instead.
  ///
  /// These screens are single-column reading surfaces - a photo, a step of
  /// working, an equation. Past roughly this width a line of body text runs
  /// well beyond a comfortable measure, so extra window width is better spent
  /// on margins than on longer lines.
  static const double maxContentWidth = 600;

  /// Bounds on how far the design canvas may be scaled.
  ///
  /// ScreenUtil scales strictly linearly off the viewport, so an unclamped
  /// 1440px-wide window renders every `.w` and `.sp` value at 4x: 14px body
  /// text becomes 56px. The ceiling keeps large windows legible; the floor
  /// stops very narrow ones from shrinking text into illegibility.
  static const double minScale = 0.85;
  static const double maxScale = 1.3;
}

/// Bounds the app to a single readable column and pins the UI scale.
///
/// Install once, as `MaterialApp.builder`, so every route and every route-level
/// dialog or bottom sheet inherits the same column and the same scale.
///
/// Two things happen here, and they have to happen together:
///
///  * The column is capped at [AppLayout.maxContentWidth] and centred, with the
///    surrounding window painted in a backdrop colour.
///  * [ScreenUtil] is configured from the *column* rather than the window, with
///    the scale clamped. The design size is derived rather than fixed: feeding
///    the package `columnWidth / desiredScale` makes its `scaleWidth` come out
///    at exactly the clamped scale, which is the only lever it offers for
///    bounding growth.
///
/// Configuring runs through [ScreenUtilInit] rather than a bare
/// [ScreenUtil.configure] call because the package keeps its metrics in a
/// global singleton rather than in the widget tree. Reconfiguring alone leaves
/// everything already mounted painting at the stale scale, since widgets read
/// `.w`/`.sp` imperatively and so never subscribe to the change.
/// `ScreenUtilInit` observes window metrics and walks its subtree marking
/// widgets dirty, which is what makes a resize or a rotation take effect.
///
/// It resolves those metrics from `View.of(context)`, so it always measures the
/// whole window and cannot be pointed at the narrowed column - its
/// `useInheritedMediaQuery` flag reads like the escape hatch for that but is
/// declared and never used. The design size compensates: handing it
/// `windowWidth / desiredScale` makes `scaleWidth` resolve to exactly the
/// clamped scale, which is the only lever the package offers for bounding
/// growth. Nothing in the app reads `ScreenUtil().screenWidth`, `.sw` or `.sh`,
/// so the singleton still describing the window is inert.
///
/// On any viewport narrower than [AppLayout.maxContentWidth] - every phone -
/// this resolves to the previous behaviour exactly: full width, design size
/// untouched.
///
/// One consequence of wrapping the Navigator rather than each page: route-level
/// modals live in the Navigator's own overlay, so a bottom sheet or dialog is
/// bounded to the column too - which is what keeps it phone-shaped instead of
/// stretching a short sheet across a 1440px window - but its scrim is bounded
/// with it. On a wide window the margins beside the column stay undimmed and do
/// not accept tap-to-dismiss. Pushing the clamp below the Navigator would fix
/// the scrim at the cost of full-width modals and a per-screen opt-in that new
/// screens would forget, so the scrim is the side that gives.
class ResponsiveAppShell extends StatelessWidget {
  final Widget child;

  const ResponsiveAppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final window = mediaQuery.size;

    final contentWidth = math.min(window.width, AppLayout.maxContentWidth);
    final contentQuery = mediaQuery.copyWith(
      size: Size(contentWidth, window.height),
    );

    // Derived from the window, but scaled by the column: the width the user
    // actually gets is what should decide how big things look.
    final designSize = Size(
      window.width / _scaleFor(contentWidth, AppLayout.designSize.width),
      window.height / _scaleFor(window.height, AppLayout.designSize.height),
    );

    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: SizedBox(
          width: contentWidth,
          child: ScreenUtilInit(
            designSize: designSize,
            // Load-bearing. `splitScreenMode` floors the height at 700px, which
            // would desynchronise the vertical scale from the clamp on short
            // windows. `minTextAdapt` is inert either way because
            // `fontSizeResolver` overrides it - which is why setting that flag
            // alone had never done anything here.
            splitScreenMode: false,
            minTextAdapt: false,
            fontSizeResolver: FontSizeResolvers.width,
            builder: (_, __) => MediaQuery(data: contentQuery, child: child),
          ),
        ),
      ),
    );
  }

  static double _scaleFor(double available, double design) {
    return (available / design).clamp(AppLayout.minScale, AppLayout.maxScale);
  }
}
