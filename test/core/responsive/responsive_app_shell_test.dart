// The shell exists to stop the UI from scaling itself apart, so these tests
// assert concrete pixel values rather than widget presence. ScreenUtil scales
// linearly off the viewport with no ceiling of its own: before the shell, a
// 1440px-wide window rendered 14px body text at 56px and 16px gutters at 64px,
// while corner radii grew only 1.3x. The numbers below are the contract.
import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/shared/design/atomic/atoms/quest_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

class _Probe {
  double? gutter16w;
  double? body14sp;
  double? heading24sp;
  double? gap24h;
  double? radius16r;
  Size? mediaSize;
  double? paintedWidth;
}

void main() {
  /// Pumps the shell at [window] and reports what the sizing extensions
  /// actually evaluate to inside it.
  Future<_Probe> probeAt(WidgetTester tester, Size window) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final probe = _Probe();

    await tester.pumpWidget(
      MaterialApp(
        home: ResponsiveAppShell(
          child: Builder(
            builder: (context) {
              probe
                ..gutter16w = 16.w
                ..body14sp = 14.sp
                ..heading24sp = 24.sp
                ..gap24h = 24.h
                ..radius16r = 16.r
                ..mediaSize = MediaQuery.sizeOf(context);
              return const SizedBox.expand(key: Key('content'));
            },
          ),
        ),
      ),
    );
    await tester.pump();

    probe.paintedWidth = tester.getSize(find.byKey(const Key('content'))).width;
    return probe;
  }

  group('phone viewports keep the design canvas untouched', () {
    testWidgets('at the 360x690 design size everything is 1:1', (tester) async {
      final probe = await probeAt(tester, const Size(360, 690));

      expect(probe.gutter16w, closeTo(16, 0.5));
      expect(probe.body14sp, closeTo(14, 0.5));
      expect(probe.gap24h, closeTo(24, 0.5));
      expect(probe.paintedWidth, 360);
    });

    testWidgets('a 390x844 phone fills the width and scales gently',
        (tester) async {
      final probe = await probeAt(tester, const Size(390, 844));

      // Below maxContentWidth the column still spans the whole screen - the
      // clamp must never letterbox a phone.
      expect(probe.paintedWidth, 390);
      expect(probe.mediaSize!.width, 390);
      expect(probe.body14sp, closeTo(15.2, 0.3));
      expect(probe.gutter16w, closeTo(17.3, 0.3));
    });

    testWidgets(
        'a very narrow window floors the scale instead of shrinking '
        'text away', (tester) async {
      final probe = await probeAt(tester, const Size(240, 600));

      expect(probe.paintedWidth, 240);
      // 240/360 would be 0.67x; the floor holds text at 0.85x.
      expect(probe.body14sp, closeTo(14 * AppLayout.minScale, 0.3));
    });
  });

  group('desktop viewports clamp both the column and the scale', () {
    testWidgets('a 1440x900 laptop widens the column and keeps text readable',
        (tester) async {
      const window = Size(1440, 900);
      final probe = await probeAt(tester, window);
      final scale = AppLayout.scaleFor(window);

      expect(probe.paintedWidth, AppLayout.maxContentWidth);
      expect(probe.mediaSize!.width, AppLayout.maxContentWidth);

      // This window is short before it is narrow: 900px of height fits the
      // 690px canvas only 1.3 times, so height is what sets the scale here and
      // the ceiling is never reached.
      expect(scale, lessThan(AppLayout.maxScale));

      // Regression guard. Unclamped this window produced scaleWidth = 4.0:
      // 14.sp rendered at 56px and 16.w at 64px, while 16.r stayed near 21px.
      expect(probe.body14sp, closeTo(14 * scale, 0.3));
      expect(probe.heading24sp, closeTo(24 * scale, 0.3));
      expect(probe.gutter16w, closeTo(16 * scale, 0.3));
      expect(probe.gap24h, closeTo(24 * scale, 0.3));
    });

    testWidgets('a 1920x1080 desktop has the room to reach the ceiling',
        (tester) async {
      const window = Size(1920, 1080);
      final probe = await probeAt(tester, window);

      expect(AppLayout.scaleFor(window), AppLayout.maxScale);
      expect(probe.paintedWidth, AppLayout.maxContentWidth);
      expect(probe.body14sp, closeTo(14 * AppLayout.maxScale, 0.3));
      expect(probe.gutter16w, closeTo(16 * AppLayout.maxScale, 0.3));
    });

    testWidgets('horizontal and vertical scales stay in proportion',
        (tester) async {
      final probe = await probeAt(tester, const Size(1440, 900));

      // The original defect was not merely "too big", it was "unevenly big":
      // width and text ran at 4.0x while height and radius ran at 1.3x, which
      // is what shattered the proportions. Tie them together explicitly.
      final widthScale = probe.gutter16w! / 16;
      final textScale = probe.body14sp! / 14;
      final heightScale = probe.gap24h! / 24;
      final radiusScale = probe.radius16r! / 16;

      expect(textScale, closeTo(widthScale, 0.05));
      expect(heightScale, closeTo(widthScale, 0.05));
      expect(radiusScale, closeTo(widthScale, 0.05));
    });

    testWidgets('carries the backdrop across the whole window, not the column',
        (tester) async {
      const window = Size(1440, 900);
      tester.view.physicalSize = window;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: ResponsiveAppShell(child: Container(color: Colors.red)),
        ),
      );

      // The margins beside the column used to be a flat fill, which read as
      // two black bars with a hard seam down each side of the page. The
      // backdrop spans the window instead, so its glow and dot grid run
      // straight through where that seam was.
      final backdrop = tester.getRect(find.byType(QuestBackdrop).first);

      expect(backdrop.width, window.width);
      expect(backdrop.height, window.height);
      expect(
        backdrop.width,
        greaterThan(AppLayout.maxContentWidth),
        reason: 'a backdrop only as wide as the column would leave the '
            'margins unpainted, which is the letterboxing this replaced',
      );
    });
  });
}
