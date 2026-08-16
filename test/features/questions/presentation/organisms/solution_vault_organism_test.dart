import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_segment_order.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_vault_organism.dart';
import 'package:doormer/src/shared/design/atomic/atoms/dashed_border_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

final _answer = diagramFirstOrder(const [
  TextSolutionSegment('The paved area is 160 square metres.'),
]);

Widget _pump({
  required bool revealed,
  required bool unlockable,
  VoidCallback? onReveal,
  bool motion = false,
  bool resisting = false,
}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: !motion),
        child: Scaffold(
        body: SingleChildScrollView(
          child: SolutionVaultOrganism(
            revealed: revealed,
            unlockable: unlockable,
            resisting: resisting,
            lockedLabel: 'Answer unlocks after step 3',
            answerBody: _answer,
            onReveal: onReveal ?? () {},
            onEnlargeVisual: (_) {},
          ),
        ),
      ),
      ),
    ),
  );
}

void main() {
  _unlockChainTests();
  _lockBobTests();
  _readyStateTests();
  testWidgets('shows the locked strip with the supplied label before the end',
      (tester) async {
    await tester.pumpWidget(_pump(revealed: false, unlockable: false));
    await tester.pump();

    expect(find.byKey(const Key('vault_locked')), findsOneWidget);
    expect(find.text('Answer unlocks after step 3'), findsOneWidget);
    expect(find.byKey(const Key('vault_revealed')), findsNothing);
    expect(find.text('The paved area is 160 square metres.'), findsNothing);
  });

  testWidgets('stays compact while locked', (tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_pump(revealed: false, unlockable: false));
    await tester.pump();

    final height = tester.getSize(find.byKey(const Key('vault_locked'))).height;
    expect(height, lessThan(72),
        reason: 'the vault must not squat at full size while locked');
  });

  testWidgets('reveals the answer body once revealed', (tester) async {
    await tester.pumpWidget(_pump(revealed: true, unlockable: true));
    await tester.pump();

    expect(find.byKey(const Key('vault_revealed')), findsOneWidget);
    expect(find.text('The paved area is 160 square metres.'), findsOneWidget);
    expect(find.byKey(const Key('vault_locked')), findsNothing);
  });

  testWidgets('tapping the unlockable vault reports upward', (tester) async {
    var reveals = 0;
    await tester.pumpWidget(
      _pump(revealed: false, unlockable: true, onReveal: () => reveals++),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('vault_locked')));
    await tester.pump();

    expect(reveals, 1);
  });

  group('the border says whether the answer has been earned', () {
    testWidgets('is broken while the vault is shut but openable',
        (tester) async {
      await tester.pumpWidget(_pump(revealed: false, unlockable: true));
      await tester.pump();

      expect(
        find.descendant(
          of: find.byKey(const Key('vault_locked')),
          matching: find.byType(DashedBorderAtom),
        ),
        findsOneWidget,
        reason: 'a solid edge would say the answer is already yours',
      );
    });

    testWidgets('is solid once the answer is out', (tester) async {
      await tester.pumpWidget(_pump(revealed: true, unlockable: true));
      await tester.pump();

      expect(find.byType(DashedBorderAtom), findsNothing);

      final decoration = tester
          .widget<Container>(find.byKey(const Key('vault_revealed')))
          .decoration as BoxDecoration;

      expect(decoration.border, isNotNull);
    });

    testWidgets('is plain while the vault is not yet relevant', (tester) async {
      await tester.pumpWidget(_pump(revealed: false, unlockable: false));
      await tester.pump();

      expect(
        find.byType(DashedBorderAtom),
        findsNothing,
        reason: 'a vault the student cannot open yet should recede, not '
            'advertise itself as openable',
      );
    });
  });
}

double _vaultScale(WidgetTester tester) {
  final transforms = tester.widgetList<Transform>(find.ancestor(
    of: find.byKey(const Key('vault_locked')),
    matching: find.byType(Transform),
  ));
  return transforms.fold<double>(1, (acc, t) => acc * t.transform.entry(0, 0));
}

void _readyStateTests() {
  group('becoming openable', () {
    testWidgets('the vault bounces once when it first becomes openable',
        (tester) async {
      await tester.pumpWidget(_pump(
        revealed: false,
        unlockable: false,
        motion: true,
      ));
      await tester.pumpAndSettle();
      expect(_vaultScale(tester), 1.0);

      await tester.pumpWidget(_pump(
        revealed: false,
        unlockable: true,
        motion: true,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      expect(_vaultScale(tester), greaterThan(1.005),
          reason: 'a vault that silently becomes openable is a vault the '
              'student never notices');

      await tester.pumpAndSettle();
      expect(_vaultScale(tester), 1.0);
    });

    testWidgets('the ring beats a few times and then leaves off',
        (tester) async {
      await tester.pumpWidget(_pump(
        revealed: false,
        unlockable: false,
        motion: true,
      ));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_pump(
        revealed: false,
        unlockable: true,
        motion: true,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byKey(const Key('vault_ready_ring')), findsOneWidget);

      // pumpAndSettle would hang forever on a ring that never stops.
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('vault_ready_ring')), findsNothing,
          reason: 'a prompt that repeats forever becomes a fixture the eye '
              'edits out');
    });

    testWidgets('a vault that mounts already openable does not bounce',
        (tester) async {
      await tester.pumpWidget(_pump(
        revealed: false,
        unlockable: true,
        motion: true,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      expect(_vaultScale(tester), 1.0,
          reason: 'returning to a page is not the moment the vault opened up');
      expect(find.byKey(const Key('vault_ready_ring')), findsNothing);
    });

    testWidgets('stays still under reduced motion', (tester) async {
      await tester.pumpWidget(_pump(revealed: false, unlockable: false));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_pump(revealed: false, unlockable: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      expect(_vaultScale(tester), 1.0);
      expect(find.byKey(const Key('vault_ready_ring')), findsNothing);
    });
  });
}

void _unlockChainTests() {
  group('the unlock', () {
    testWidgets('rattles while the lock is refusing', (tester) async {
      await tester.pumpWidget(_pump(
        revealed: false,
        unlockable: true,
        motion: true,
      ));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_pump(
        revealed: false,
        unlockable: true,
        resisting: true,
        motion: true,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));

      final shifted = tester
          .widgetList<Transform>(find.ancestor(
            of: find.byKey(const Key('vault_locked')),
            matching: find.byType(Transform),
          ))
          .fold<double>(0, (acc, t) => acc + t.transform.getTranslation().x);
      expect(shifted.abs(), greaterThan(1),
          reason: 'a lock that gives without protest hands the answer over');
      expect(find.byKey(const Key('vault_revealed')), findsNothing);

      await tester.pumpAndSettle();
    });

    testWidgets('throws paper when it opens', (tester) async {
      await tester.pumpWidget(_pump(
        revealed: false,
        unlockable: true,
        motion: true,
      ));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_pump(
        revealed: true,
        unlockable: true,
        motion: true,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byKey(const Key('vault_confetti')), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('does not celebrate a vault that was already open',
        (tester) async {
      await tester.pumpWidget(_pump(
        revealed: true,
        unlockable: true,
        motion: true,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byKey(const Key('vault_revealed')), findsOneWidget);
      expect(find.byKey(const Key('vault_confetti')), findsNothing,
          reason: 'a student who taps back and returns is not congratulated '
              'twice');
      await tester.pumpAndSettle();
    });

    testWidgets('opens at once and silently under reduced motion',
        (tester) async {
      await tester.pumpWidget(_pump(revealed: false, unlockable: true));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_pump(revealed: true, unlockable: true));
      await tester.pump();

      expect(find.byKey(const Key('vault_revealed')), findsOneWidget,
          reason: 'the answer is not allowed to wait on an animation that '
              'never runs');
      expect(find.byKey(const Key('vault_confetti')), findsNothing);
    });

    testWidgets('shuts again without ceremony when the student travels back',
        (tester) async {
      await tester.pumpWidget(_pump(
        revealed: false,
        unlockable: true,
        motion: true,
      ));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_pump(
        revealed: true,
        unlockable: true,
        motion: true,
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('vault_revealed')), findsOneWidget);

      await tester.pumpWidget(_pump(
        revealed: false,
        unlockable: false,
        motion: true,
      ));
      await tester.pump();

      expect(find.byKey(const Key('vault_locked')), findsOneWidget);
      expect(find.byKey(const Key('vault_confetti')), findsNothing);
      await tester.pumpAndSettle();
    });
  });
}

void _lockBobTests() {
  group('the shut vault', () {
    testWidgets('strains its lock a few times, then holds still',
        (tester) async {
      await tester.pumpWidget(_pump(
        revealed: false,
        unlockable: false,
        motion: true,
      ));
      // The controller starts in a post-frame callback, so the first pump only
      // schedules it. Sampling now would read the zeroth tick.
      await tester.pump();

      var lifted = 0.0;
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        final y = tester
            .widgetList<Transform>(find.ancestor(
              of: find.byIcon(Icons.lock_rounded),
              matching: find.byType(Transform),
            ))
            .fold<double>(0, (acc, t) => acc + t.transform.getTranslation().y);
        if (y < lifted) lifted = y;
      }
      expect(lifted, lessThan(-1),
          reason: 'a lock that never moves is scenery; one that strains is '
              'something holding back a thing the student wants');

      // Hanging here is the failure: an endless bob makes every screen with a
      // vault untestable.
      await tester.pumpAndSettle();
    });
  });
}
