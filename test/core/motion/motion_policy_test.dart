import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _probe({
  required bool disableAnimations,
  required void Function(BuildContext) onBuild,
}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Builder(
      builder: (context) {
        onBuild(context);
        return const SizedBox();
      },
    ),
  );
}

void main() {
  testWidgets('runs motion by default', (tester) async {
    late bool on;
    await tester.pumpWidget(
      _probe(disableAnimations: false, onBuild: (c) => on = MotionPolicy.of(c)),
    );
    expect(on, isTrue);
  });

  testWidgets('stops motion when the user asks for stillness', (tester) async {
    late bool on;
    late bool idle;
    late Duration d;
    await tester.pumpWidget(_probe(
      disableAnimations: true,
      onBuild: (c) {
        on = MotionPolicy.of(c);
        idle = MotionPolicy.idle(c);
        d = MotionPolicy.duration(c, const Duration(milliseconds: 480));
      },
    ));

    expect(on, isFalse);
    expect(idle, isFalse);
    expect(d, Duration.zero);
  });

  testWidgets('leaves entering content visible when motion is off',
      (tester) async {
    late double value;
    await tester.pumpWidget(_probe(
      disableAnimations: true,
      // 0 is the start of a fade-in. With motion off the content must be shown,
      // not held at its start value.
      onBuild: (c) => value = MotionPolicy.settled(c, 0),
    ));

    expect(
      value,
      1.0,
      reason: 'turning off motion must cost the user movement, never '
          'information -- content that fades in must simply be there',
    );
  });

  testWidgets('keeps motion on when there is no MediaQuery', (tester) async {
    late bool on;
    await tester.pumpWidget(Builder(
      builder: (context) {
        on = MotionPolicy.of(context);
        return const SizedBox();
      },
    ));

    expect(on, isTrue);
  });
}
