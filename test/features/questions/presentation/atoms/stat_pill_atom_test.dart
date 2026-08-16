import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/atoms/stat_pill_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pump({required bool alive, bool motion = true}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: !motion),
        child: Scaffold(
          body: Center(
            child: StatPillAtom(
              icon: Icons.local_fire_department_rounded,
              iconKey: const Key('pill_emblem'),
              label: '3-day',
              accent: QuestPalette.amber,
              alive: alive,
            ),
          ),
        ),
      ),
    ),
  );
}

double _lift(WidgetTester tester) => tester
    .widgetList<Transform>(find.ancestor(
      of: find.byKey(const Key('pill_emblem')),
      matching: find.byType(Transform),
    ))
    .fold<double>(0, (acc, t) => acc + t.transform.getTranslation().y);

Future<double> _travel(WidgetTester tester) async {
  var lowest = 0.0;
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    final lift = _lift(tester);
    if (lift < lowest) lowest = lift;
  }
  return lowest;
}

void main() {
  group('StatPillAtom', () {
    testWidgets('a living stat flickers on arrival', (tester) async {
      await tester.pumpWidget(_pump(alive: true));
      // The controller starts in a post-frame callback, so the first pump only
      // schedules it. Sampling now would read the zeroth tick.
      await tester.pump();

      expect(await _travel(tester), lessThan(-1),
          reason: 'a streak is a thing that can be lost; a number that never '
              'moves does not say that');
      await tester.pumpAndSettle();
    });

    testWidgets('a plain total holds still', (tester) async {
      await tester.pumpWidget(_pump(alive: false));
      await tester.pump();

      expect(await _travel(tester), 0.0,
          reason: 'banked XP cannot be lost, so it has no reason to fidget');
    });

    testWidgets('the flicker stops', (tester) async {
      await tester.pumpWidget(_pump(alive: true));
      await tester.pump();
      // Hanging here is the failure: an endless flame makes every screen with
      // a HUD untestable.
      await tester.pumpAndSettle();

      final settled = _lift(tester);
      await tester.pump(const Duration(milliseconds: 500));
      expect(_lift(tester), settled);
      expect(settled, 0.0);
    });

    testWidgets('holds still under reduced motion', (tester) async {
      await tester.pumpWidget(_pump(alive: true, motion: false));
      await tester.pump();

      expect(await _travel(tester), 0.0);
    });
  });
}
