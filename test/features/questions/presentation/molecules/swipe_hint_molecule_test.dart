import 'dart:math' as math;

import 'package:doormer/src/features/questions/presentation/molecules/swipe_hint_molecule.dart';
import 'package:doormer/src/shared/design/atomic/atoms/idle_beat_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pump({bool used = false, bool motion = true}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: !motion),
        child: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SwipeHintMolecule(used: used),
          ),
        ),
      ),
    ),
  );
}

double _opacity(WidgetTester tester) {
  final finder = find.byKey(const Key('swipe_hint'));
  if (finder.evaluate().isEmpty) return 0;
  return tester
      .widgetList<FadeTransition>(find.descendant(
        of: finder,
        matching: find.byType(FadeTransition),
      ))
      .fold<double>(1, (acc, f) => acc * f.opacity.value);
}

/// The furthest right the chevron travels while nudging.
Future<double> _nudgeReach(WidgetTester tester) async {
  var reach = 0.0;
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 40));
    final finder = find.byKey(const Key('swipe_hint_chevron'));
    if (finder.evaluate().isEmpty) continue;
    final dx = tester
        .widgetList<Transform>(find.ancestor(
          of: finder,
          matching: find.byType(Transform),
        ))
        .fold<double>(0, (acc, t) => acc + t.transform.getTranslation().x);
    reach = math.max(reach, dx);
  }
  return reach;
}

void main() {
  testWidgets('says which way to go, and points that way', (tester) async {
    await tester.pumpWidget(_pump());
    await tester.pump();

    expect(find.text('Swipe'), findsOneWidget);
    expect(find.textContaining('between steps'), findsOneWidget);
    expect(find.byKey(const Key('swipe_hint_chevron')), findsOneWidget);
  });

  testWidgets('nudges rightwards to suggest the gesture', (tester) async {
    await tester.pumpWidget(_pump());
    await tester.pump();

    expect(await _nudgeReach(tester), greaterThan(2.0),
        reason: 'a still arrow is a label, a moving one is an instruction');
  });

  testWidgets('stops nudging rather than pestering forever', (tester) async {
    await tester.pumpWidget(_pump());
    await tester.pump();
    await tester.pumpAndSettle();
  });

  testWidgets('retires on its own once it has had its say', (tester) async {
    await tester.pumpWidget(_pump());
    await tester.pump();

    expect(_opacity(tester), greaterThan(0.9));

    await tester.pump(const Duration(milliseconds: 3400));
    await tester.pump(const Duration(milliseconds: 600));
    expect(_opacity(tester), lessThan(0.05),
        reason: 'it steps aside for a student who never needed it');
  });

  testWidgets('leaves faster once the student has moved a step',
      (tester) async {
    await tester.pumpWidget(_pump());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.pumpWidget(_pump(used: true));
    await tester.pump(const Duration(milliseconds: 350));

    expect(_opacity(tester), lessThan(0.05),
        reason: 'the question has been answered, so it should stop talking');
  });

  testWidgets('never intercepts a tap meant for the buttons under it',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => tapped = true,
                ),
              ),
              const Align(
                alignment: Alignment.center,
                child: SwipeHintMolecule(),
              ),
            ],
          ),
        ),
      ),
    ));
    await tester.pump();

    await tester.tapAt(tester.getCenter(find.byKey(const Key('swipe_hint'))));
    await tester.pump();

    expect(tapped, isTrue,
        reason: 'the hint floats over the dock without swallowing it');
  });

  testWidgets('is simply gone when motion is off', (tester) async {
    await tester.pumpWidget(_pump(motion: false));
    await tester.pump();

    expect(find.byKey(const Key('swipe_hint')), findsNothing,
        reason: 'a hint about a gesture is noise if it cannot move');
    expect(find.byType(IdleBeatAtom), findsNothing);
  });

  testWidgets('wraps its words instead of stretching across', (tester) async {
    await tester.pumpWidget(_pump());
    await tester.pump();

    final pill = tester.getSize(find.byKey(const Key('swipe_hint')));
    final surface = tester.getSize(find.byType(MaterialApp));
    expect(pill.width, lessThan(surface.width - 20),
        reason: 'it wraps its words rather than spanning the screen');
  });

  testWidgets('takes up no room, so the buttons do not shift', (tester) async {
    await tester.pumpWidget(_pump());
    await tester.pump();

    expect(tester.getSize(find.byType(SwipeHintMolecule)).height, 0,
        reason: 'it floats over the dock rather than pushing it down');
  });
}
