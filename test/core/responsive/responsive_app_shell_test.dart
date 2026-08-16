// The shell exists to stop the UI from scaling itself apart, so these tests
// assert concrete pixel values rather than widget presence. ScreenUtil scales
// linearly off the viewport with no ceiling of its own: before the shell, a
// 1440px-wide window rendered 14px body text at 56px and 16px gutters at 64px,
// while corner radii grew only 1.3x. The numbers below are the contract.
import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
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

    testWidgets('a very narrow window floors the scale instead of shrinking '
        'text away', (tester) async {
      final probe = await probeAt(tester, const Size(240, 600));

      expect(probe.paintedWidth, 240);
      // 240/360 would be 0.67x; the floor holds text at 0.85x.
      expect(probe.body14sp, closeTo(14 * AppLayout.minScale, 0.3));
    });
  });

  group('desktop viewports clamp both the column and the scale', () {
    testWidgets('a 1440x900 laptop caps the column and keeps text readable',
        (tester) async {
      final probe = await probeAt(tester, const Size(1440, 900));

      expect(probe.paintedWidth, AppLayout.maxContentWidth);
      expect(probe.mediaSize!.width, AppLayout.maxContentWidth);

      // Regression guard. Unclamped this window produced scaleWidth = 4.0:
      // 14.sp rendered at 56px and 16.w at 64px, while 16.r stayed near 21px.
      expect(probe.body14sp, closeTo(14 * AppLayout.maxScale, 0.3));
      expect(probe.heading24sp, closeTo(24 * AppLayout.maxScale, 0.3));
      expect(probe.gutter16w, closeTo(16 * AppLayout.maxScale, 0.3));
      expect(probe.gap24h, closeTo(24 * AppLayout.maxScale, 0.3));
    });

    testWidgets('a 1920x1080 desktop clamps to the same numbers',
        (tester) async {
      final probe = await probeAt(tester, const Size(1920, 1080));

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

    testWidgets('the window outside the column is painted, not left blank',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveAppShell(child: Container(color: Colors.red)),
        ),
      );

      final backdrop = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(ResponsiveAppShell),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      final scheme = Theme.of(
        tester.element(find.byType(ResponsiveAppShell)),
      ).colorScheme;

      expect(backdrop.color, scheme.surfaceContainerHighest);
    });
  });
}
