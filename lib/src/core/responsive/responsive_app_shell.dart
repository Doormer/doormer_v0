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
/// Configuring happens through [ScreenUtil.configure] rather than by nesting a
/// `ScreenUtilInit`, because that widget resolves its own metrics from
/// `View.of(context)` and so cannot be pointed at a narrowed column. Its
/// `useInheritedMediaQuery` flag reads like the escape hatch for this but is
/// declared and never used. Calling `configure` from `build` mirrors what
/// `ScreenUtilInit` does internally, and depending on [MediaQuery] here means
/// a window resize re-runs it.
///
/// On any viewport narrower than [AppLayout.maxContentWidth] - every phone -
/// this resolves to the previous behaviour exactly: full width, design size
/// untouched.
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

    ScreenUtil.configure(
      data: contentQuery,
      designSize: Size(
        contentWidth / _scaleFor(contentWidth, AppLayout.designSize.width),
        window.height / _scaleFor(window.height, AppLayout.designSize.height),
      ),
      // Load-bearing. `splitScreenMode` floors the height at 700px, which would
      // desynchronise the vertical scale from the clamp on short windows.
      splitScreenMode: false,
      // Both of these must be passed on every call, not just the first:
      // `configure` resolves an omitted argument by reading the corresponding
      // `late` field back off the singleton, which throws before anything has
      // initialised it. `minTextAdapt` is inert regardless, because
      // `fontSizeResolver` overrides it - which is why setting that flag alone
      // had never done anything here.
      minTextAdapt: false,
      fontSizeResolver: FontSizeResolvers.width,
    );

    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: SizedBox(
          width: contentWidth,
          child: MediaQuery(data: contentQuery, child: child),
        ),
      ),
    );
  }

  static double _scaleFor(double available, double design) {
    return (available / design).clamp(AppLayout.minScale, AppLayout.maxScale);
  }
}
