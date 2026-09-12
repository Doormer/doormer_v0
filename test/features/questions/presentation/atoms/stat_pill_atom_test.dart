import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/idle_beat_atom.dart';
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
  _stakeTests();

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

/// The pill goes to stake in the same rebuild that the last step arrives, so
/// the harness has to be able to flip the flag on a live tree.
class _StakeHarness extends StatefulWidget {
  final bool motion;

  const _StakeHarness({this.motion = true});

  @override
  State<_StakeHarness> createState() => _StakeHarnessState();
}

class _StakeHarnessState extends State<_StakeHarness> {
  bool _atStake = false;
  String _label = '3-day';

  void raise() => setState(() => _atStake = true);

  void relabel() => setState(() => _label = '4-day');

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: !widget.motion),
          child: Scaffold(
            body: Center(
              child: StatPillAtom(
                key: const Key('pill'),
                icon: Icons.local_fire_department_rounded,
                iconKey: const Key('pill_emblem'),
                label: _label,
                accent: QuestPalette.amber,
                alive: true,
                atStake: _atStake,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The pill's own scale, ignoring whatever the emblem is doing inside it.
///
/// Read from the one keyed transform rather than folded over every ancestor:
/// the emblem's flare also scales, and past its overshoot it would carry the
/// fold above 1 all on its own, so a fold would report a pop that never
/// happened.
double _pillScale(WidgetTester tester) {
  final pop = find.byKey(const Key('pill_pop'));
  if (pop.evaluate().isEmpty) return 1.0;
  return tester.widget<Transform>(pop).transform.entry(0, 0);
}

Future<double> _peakPillScale(WidgetTester tester) async {
  var peak = 1.0;
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 25));
    final s = _pillScale(tester);
    if (s > peak) peak = s;
  }
  return peak;
}

void _stakeTests() {
  group('going to stake', () {
    testWidgets('does nothing until the streak is actually at risk',
        (tester) async {
      await tester.pumpWidget(const _StakeHarness());
      await tester.pump();

      expect(await _peakPillScale(tester), closeTo(1.0, 0.001),
          reason: 'a streak that is safe has nothing to announce');
    });

    testWidgets('swells the whole pill once when the last step arrives',
        (tester) async {
      await tester.pumpWidget(const _StakeHarness());
      await tester.pump();
      await tester.pumpAndSettle();

      tester
          .state<_StakeHarnessState>(find.byType(_StakeHarness))
          .raise();
      await tester.pump();

      final peak = await _peakPillScale(tester);
      expect(peak, greaterThan(1.05));
      expect(peak, lessThan(1.35),
          reason: 'a warning, not a jump scare');

      await tester.pumpAndSettle();
      expect(_pillScale(tester), closeTo(1.0, 0.001),
          reason: 'the pill settles back to its own size');
    });

    testWidgets('flares the flame in from small and tilted', (tester) async {
      await tester.pumpWidget(const _StakeHarness());
      await tester.pump();
      await tester.pumpAndSettle();

      tester
          .state<_StakeHarnessState>(find.byType(_StakeHarness))
          .raise();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));

      final flare = tester.widget<FadeTransition>(
        find.byKey(const Key('pill_flare')),
      );
      expect(flare.opacity.value, lessThan(0.9),
          reason: 'the flame fades in rather than snapping on');

      final scale = tester
          .widgetList<Transform>(find.ancestor(
            of: find.byKey(const Key('pill_emblem')),
            matching: find.byType(Transform),
          ))
          .fold<double>(1, (acc, t) => acc * t.transform.entry(0, 0));
      expect(scale, lessThan(0.9),
          reason: 'it grows into place from small');

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pill_flare')), findsNothing,
          reason: 'once it has arrived nothing is left dimming or shrinking it');
      expect(find.byKey(const Key('pill_emblem')), findsOneWidget);
    });

    testWidgets('stops the flame bobbing while it is being re-lit',
        (tester) async {
      await tester.pumpWidget(const _StakeHarness());
      await tester.pump();
      await tester.pumpAndSettle();

      tester.state<_StakeHarnessState>(find.byType(_StakeHarness)).raise();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(IdleBeatAtom), findsNothing,
          reason: 'the idle waits its turn instead of fighting the flare');

      await tester.pumpAndSettle();
      expect(find.byType(IdleBeatAtom), findsOneWidget,
          reason: 'and picks back up once the flame has arrived');
    });

    testWidgets('warns once, however often the bar redraws', (tester) async {
      await tester.pumpWidget(const _StakeHarness());
      await tester.pump();
      await tester.pumpAndSettle();

      final harness = tester.state<_StakeHarnessState>(find.byType(_StakeHarness));
      harness.raise();
      await tester.pump();
      await tester.pumpAndSettle();

      harness.relabel();
      await tester.pump();

      expect(await _peakPillScale(tester), closeTo(1.0, 0.001),
          reason: 'the stakes did not change again, so nothing was announced');
    });

    testWidgets('holds still when motion is off', (tester) async {
      await tester.pumpWidget(const _StakeHarness(motion: false));
      await tester.pump();

      tester
          .state<_StakeHarnessState>(find.byType(_StakeHarness))
          .raise();
      await tester.pump();

      expect(await _peakPillScale(tester), closeTo(1.0, 0.001));
      expect(find.byKey(const Key('pill_flare')), findsNothing);
      expect(find.byKey(const Key('pill_emblem')), findsOneWidget,
          reason: 'the flame is still there, it just does not perform');
    });
  });
}
