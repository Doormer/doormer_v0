import 'package:doormer/src/shared/design/atomic/atoms/idle_beat_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the phase at every rebuild so a test can describe the whole run
/// rather than guess at one instant of it.
class _Recorder {
  final List<double> phases = [];

  Widget pump({
    bool motion = true,
    int beats = 3,
    Duration period = const Duration(milliseconds: 100),
    Duration delay = Duration.zero,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: !motion),
        child: IdleBeatAtom(
          period: period,
          beats: beats,
          delay: delay,
          builder: (context, phase, child) {
            phases.add(phase);
            return const SizedBox(width: 10, height: 10);
          },
        ),
      ),
    );
  }

  double get peak => phases.reduce((a, b) => a > b ? a : b);
}

void main() {
  group('IdleBeatAtom', () {
    testWidgets('beats the requested number of times and then rests',
        (tester) async {
      final rec = _Recorder();
      await tester.pumpWidget(rec.pump(beats: 3));
      // The controller starts in a post-frame callback, so the first pump only
      // schedules it. Sampling now would read the zeroth tick.
      await tester.pump();

      // Every beat sweeps 0 to 1, so a run of three has three descents.
      var descents = 0;
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      for (var i = 1; i < rec.phases.length; i++) {
        if (rec.phases[i] < rec.phases[i - 1] - 0.3) descents++;
      }
      expect(descents, 3,
          reason: 'the run must be as long as it was asked to be, no more');

      await tester.pumpAndSettle();
      expect(rec.phases.last, 0.0, reason: 'it settles where it started');
    });

    testWidgets('never moves under reduced motion', (tester) async {
      final rec = _Recorder();
      await tester.pumpWidget(rec.pump(motion: false));
      await tester.pump();
      // Stepped, not jumped: one long pump advances the controller straight to
      // its end value and skips every intermediate frame, so a running
      // animation would look identical to a still one.
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }

      expect(rec.peak, 0.0);
    });

    testWidgets('holds still through the delay first', (tester) async {
      final rec = _Recorder();
      await tester.pumpWidget(rec.pump(
        delay: const Duration(milliseconds: 300),
        period: const Duration(milliseconds: 100),
      ));
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }

      expect(rec.peak, 0.0,
          reason: 'a beat that fires during an arrival competes with it');

      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(rec.peak, greaterThan(0));
      await tester.pumpAndSettle();
    });

    testWidgets('settles, so it cannot hang a pumpAndSettle', (tester) async {
      final rec = _Recorder();
      await tester.pumpWidget(rec.pump(beats: 2));
      // Hanging here is the failure: one endless loop makes every test that
      // renders this subtree untestable, however far away it sits.
      await tester.pumpAndSettle();

      expect(rec.phases.last, 0.0);
    });
  });
}
