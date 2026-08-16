import 'package:doormer/src/features/questions/presentation/atoms/xp_sticker_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pump({bool motion = true}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: !motion),
        child: const Scaffold(body: Center(child: XpStickerAtom(label: '+15 XP'))),
      ),
    ),
  );
}

double _opacity(WidgetTester tester) => tester
    .widgetList<Opacity>(find.ancestor(
      of: find.byKey(const Key('step_xp_sticker')),
      matching: find.byType(Opacity),
    ))
    .fold<double>(1, (acc, o) => acc * o.opacity);

double _angle(WidgetTester tester) => tester
    .widgetList<Transform>(find.ancestor(
      of: find.byKey(const Key('step_xp_sticker')),
      matching: find.byType(Transform),
    ))
    .fold<double>(0, (acc, t) {
      final m = t.transform;
      // Rotation only: translation and scale leave entry(1,0) at zero.
      return acc + m.entry(1, 0);
    });

void main() {
  group('XpStickerAtom', () {
    testWidgets('drops onto the card rather than appearing on it',
        (tester) async {
      await tester.pumpWidget(_pump());
      // The controller starts in a post-frame callback, so the first pump only
      // schedules it. Sampling now would read the zeroth tick.
      await tester.pump();

      expect(_opacity(tester), 0.0,
          reason: 'a reward that is simply present was never awarded');

      await tester.pump(const Duration(milliseconds: 200));
      expect(_opacity(tester), greaterThan(0));
      expect(_opacity(tester), lessThan(1));

      await tester.pumpAndSettle();
      expect(_opacity(tester), 1.0);
    });

    testWidgets('is legible and square-on once it has landed', (tester) async {
      await tester.pumpWidget(_pump());
      await tester.pumpAndSettle();

      expect(find.text('+15 XP'), findsOneWidget);
      // Three degrees, as a rotation matrix entry: sin(3deg) = 0.052.
      expect(_angle(tester), closeTo(0.052, 0.01),
          reason: 'it must come to rest on its tilt, not wherever the last '
              'wiggle left it');
    });

    testWidgets('fidgets a few times after it lands, then holds still',
        (tester) async {
      await tester.pumpWidget(_pump());
      await tester.pump();

      // Past the drop and its settling delay, so nothing below is measuring
      // the arrival by mistake.
      for (var i = 0; i < 17; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      const rest = 0.052;

      var moved = false;
      for (var i = 0; i < 240; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if ((_angle(tester) - rest).abs() > 0.01) moved = true;
      }
      expect(moved, isTrue,
          reason: 'a sticker that never moves after it lands is not noticed');

      // Hanging here is the failure: an endless wiggle makes every screen that
      // shows a step card untestable.
      await tester.pumpAndSettle();
      final settled = _angle(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(_angle(tester), settled);
    });

    testWidgets('is simply there under reduced motion', (tester) async {
      await tester.pumpWidget(_pump(motion: false));
      await tester.pump();

      expect(_opacity(tester), 1.0,
          reason: 'the reward is not allowed to wait on an animation that '
              'never runs');
      await tester.pumpAndSettle();
    });
  });
}
