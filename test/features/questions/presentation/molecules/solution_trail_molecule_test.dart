import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/molecules/solution_trail_molecule.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

List<SolutionTrailNode> _nodes(int count, int currentIndex) {
  return [
    for (var i = 0; i < count; i++)
      SolutionTrailNode(
        displayNumber: i + 1,
        state: i < currentIndex
            ? SolutionTrailNodeState.done
            : i == currentIndex
                ? SolutionTrailNodeState.current
                : SolutionTrailNodeState.upcoming,
        semanticsLabel: 'Step ${i + 1}',
        travelTo: i < currentIndex ? i : null,
      ),
  ];
}

Widget _pump(
  List<SolutionTrailNode> nodes, {
  double width = 358,
  void Function(int position)? onNodeTap,
  bool motion = false,
}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        // The current node beats forever, so tests opt into motion only when
        // they are measuring it -- otherwise every pump would wait on a loop.
        data: MediaQueryData(disableAnimations: !motion),
        child: Scaffold(
          body: SizedBox(
            width: width,
            child: SolutionTrailMolecule(nodes: nodes, onNodeTap: onNodeTap),
          ),
        ),
      ),
    ),
  );
}

void main() {
  _chainTests();
  _inviteRingTests();
  testWidgets('renders one node per step with a tick on completed steps',
      (tester) async {
    await tester.pumpWidget(_pump(_nodes(3, 1)));
    await tester.pump();

    expect(find.byKey(const Key('trail_node_0')), findsOneWidget);
    expect(find.byKey(const Key('trail_node_1')), findsOneWidget);
    expect(find.byKey(const Key('trail_node_2')), findsOneWidget);

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('never shrinks a node below the 34px floor', (tester) async {
    await tester.pumpWidget(_pump(_nodes(9, 0), width: 200));
    await tester.pump();

    for (var i = 0; i < 9; i++) {
      final size = tester.getSize(find.byKey(Key('trail_node_$i')));
      expect(
        size.width,
        greaterThanOrEqualTo(SolutionTrailMolecule.minNodeSize - 0.5),
        reason: 'without the floor the trail collapses to 0px at nine steps',
      );
    }
  });

  testWidgets('renders an icon instead of a number when the node carries one',
      (tester) async {
    await tester.pumpWidget(_pump(const [
      SolutionTrailNode(
        displayNumber: 0,
        state: SolutionTrailNodeState.current,
        semanticsLabel: 'The plan',
        icon: Icons.flag_outlined,
      ),
      SolutionTrailNode(
        displayNumber: 1,
        state: SolutionTrailNodeState.upcoming,
        semanticsLabel: 'Step 1',
      ),
    ]));
    await tester.pump();

    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    expect(find.text('0'), findsNothing,
        reason: 'a briefing node has no step number to show');
    expect(find.text('1'), findsOneWidget,
        reason: 'step numbering must not shift because of the briefing node');
  });

  testWidgets('a done marker keeps its own icon rather than becoming a tick',
      (tester) async {
    await tester.pumpWidget(_pump(const [
      SolutionTrailNode(
        displayNumber: 0,
        state: SolutionTrailNodeState.done,
        semanticsLabel: 'The plan',
        icon: Icons.flag_rounded,
        shape: SolutionTrailNodeShape.marker,
      ),
    ]));
    await tester.pump();

    // The two markers are destinations, not stops. A ticked vault would say
    // "step complete" where it should say "opened", so a marker keeps its
    // identity and only its colour changes.
    expect(find.byIcon(Icons.flag_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('a done step still collapses to a tick', (tester) async {
    await tester.pumpWidget(_pump(_nodes(2, 1)));
    await tester.pump();

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('1'), findsNothing,
        reason: 'a read step shows that it is read, not its number');
  });

  group('travel', _travelTests);
  group('panning', _panTests);
  group('edges', _edgeTests);
}

void _travelTests() {
  testWidgets('tapping a step already read travels back to it', (tester) async {
    final travelled = <int>[];
    await tester.pumpWidget(
      _pump(_nodes(4, 2), onNodeTap: travelled.add),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('trail_node_tap_0')));
    await tester.pump();

    expect(travelled, [0]);
  });

  testWidgets('the road ahead is not tappable', (tester) async {
    final travelled = <int>[];
    await tester.pumpWidget(
      _pump(_nodes(4, 1), onNodeTap: travelled.add),
    );
    await tester.pump();

    expect(find.byKey(const Key('trail_node_tap_2')), findsNothing);
    expect(find.byKey(const Key('trail_node_tap_1')), findsNothing,
        reason: 'the step being read is not somewhere to travel to');
  });

  testWidgets('a node with no travel target stays inert even when done',
      (tester) async {
    final travelled = <int>[];
    await tester.pumpWidget(_pump(
      const [
        SolutionTrailNode(
          displayNumber: 0,
          state: SolutionTrailNodeState.done,
          semanticsLabel: 'The answer',
          icon: Icons.lock_open_rounded,
          shape: SolutionTrailNodeShape.marker,
        ),
      ],
      onNodeTap: travelled.add,
    ));
    await tester.pump();

    expect(find.byKey(const Key('trail_node_tap_0')), findsNothing);
  });
}

void _panTests() {
  testWidgets('brings the current node back into view when it moves past the end',
      (tester) async {
    await tester.pumpWidget(_pump(_nodes(12, 0), width: 300));
    await tester.pump();

    final controller = tester
        .widget<SingleChildScrollView>(
            find.byKey(const Key('solution_trail_scroll')))
        .controller!;
    expect(controller.offset, 0);

    await tester.pumpWidget(_pump(_nodes(12, 9), width: 300));
    await tester.pump();
    await tester.pump();

    expect(controller.offset, greaterThan(0),
        reason: 'a current node past the fold must be panned into view');

    final nodeCentre = tester.getCenter(find.byKey(const Key('trail_node_9'))).dx;
    final stripCentre =
        tester.getCenter(find.byKey(const Key('solution_trail_scroll'))).dx;
    expect((nodeCentre - stripCentre).abs(), lessThan(40),
        reason: 'the current node lands near the middle of the strip');
  });

  testWidgets('does not scroll when the whole trail already fits',
      (tester) async {
    await tester.pumpWidget(_pump(_nodes(3, 0), width: 358));
    await tester.pump();

    await tester.pumpWidget(_pump(_nodes(3, 2), width: 358));
    await tester.pump();
    await tester.pump();

    final controller = tester
        .widget<SingleChildScrollView>(
            find.byKey(const Key('solution_trail_scroll')))
        .controller!;
    expect(controller.offset, 0);
  });
}

void _edgeTests() {
  testWidgets('leaves both edges hard when the whole trail fits',
      (tester) async {
    await tester.pumpWidget(_pump(_nodes(3, 0), width: 358));
    await tester.pump();
    await tester.pump();

    expect(find.byType(ShaderMask), findsNothing);
  });

  testWidgets('fades the end the trail runs off', (tester) async {
    await tester.pumpWidget(_pump(_nodes(12, 0), width: 300));
    await tester.pump();
    await tester.pump();

    expect(find.byType(ShaderMask), findsOneWidget,
        reason: 'a trail that continues past the edge must not look finished');
  });
}

SolutionTrailNode _vaultNode(int broken) => SolutionTrailNode(
      displayNumber: 0,
      state: SolutionTrailNodeState.upcoming,
      shape: SolutionTrailNodeShape.marker,
      icon: Icons.lock_rounded,
      semanticsLabel: 'Final answer',
      chainsBroken: broken,
    );

List<SolutionTrailNode> _withVault(int broken) => [
      ..._nodes(2, 1),
      _vaultNode(broken),
    ];

int _chains(WidgetTester tester) => tester
    .widgetList<Container>(find.byType(Container))
    .where((c) {
      final d = c.decoration;
      return d is BoxDecoration && d.color == QuestPalette.dim;
    })
    .length;

void _chainTests() {
  group('the vault chains', () {
    testWidgets('strap the vault shut before any working is done',
        (tester) async {
      await tester.pumpWidget(_pump(_withVault(0)));
      await tester.pumpAndSettle();

      expect(_chains(tester), 3,
          reason: 'a vault with nothing holding it shut is just a button');
    });

    testWidgets('break one at a time as the working is done', (tester) async {
      await tester.pumpWidget(_pump(_withVault(0), motion: true));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_pump(_withVault(1), motion: true));
      await tester.pumpAndSettle();
      expect(_chains(tester), 2,
          reason: 'the chains are the working made visible; all three going '
              'at once would tie them to the button instead');

      await tester.pumpWidget(_pump(_withVault(2), motion: true));
      await tester.pumpAndSettle();
      expect(_chains(tester), 1);
    });

    testWidgets('are still flying part-way through a snap', (tester) async {
      await tester.pumpWidget(_pump(_withVault(0), motion: true));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_pump(_withVault(1), motion: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(_chains(tester), 3,
          reason: 'a chain that vanishes on the step change was never broken, '
              'it was switched off');
      await tester.pumpAndSettle();
    });

    testWidgets('are all gone once the working is finished', (tester) async {
      await tester.pumpWidget(_pump(_withVault(3)));
      await tester.pumpAndSettle();

      expect(_chains(tester), 0);
    });

    testWidgets('do not replay on a question that was already part-solved',
        (tester) async {
      await tester.pumpWidget(_pump(_withVault(2), motion: true));
      await tester.pump();

      expect(_chains(tester), 1,
          reason: 'returning to a part-solved question should not re-stage '
              'work the student did yesterday');
      await tester.pumpAndSettle();
    });

    testWidgets('go back on when the student travels back', (tester) async {
      await tester.pumpWidget(_pump(_withVault(2), motion: true));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_pump(_withVault(1), motion: true));
      await tester.pump();

      expect(_chains(tester), 2);
      await tester.pumpAndSettle();
    });

    testWidgets('break without ceremony under reduced motion', (tester) async {
      await tester.pumpWidget(_pump(_withVault(0)));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_pump(_withVault(3)));
      await tester.pump();

      expect(_chains(tester), 0);
    });

    testWidgets('never appear on a marker that was never locked',
        (tester) async {
      await tester.pumpWidget(_pump([
        const SolutionTrailNode(
          displayNumber: 0,
          state: SolutionTrailNodeState.current,
          shape: SolutionTrailNodeShape.marker,
          icon: Icons.flag_rounded,
          semanticsLabel: 'The plan',
        ),
        ..._nodes(2, 0),
      ]));
      await tester.pumpAndSettle();

      expect(_chains(tester), 0,
          reason: 'the briefing was never locked, so it was never chained');
    });
  });
}

void _inviteRingTests() {
  group('the invite ring', () {
    testWidgets('rings a few times on a node that asks to be gone back to',
        (tester) async {
      await tester.pumpWidget(_pump([
        const SolutionTrailNode(
          displayNumber: 0,
          state: SolutionTrailNodeState.done,
          shape: SolutionTrailNodeShape.marker,
          icon: Icons.flag_rounded,
          semanticsLabel: 'The plan',
          travelTo: -1,
          invites: true,
        ),
        ..._nodes(2, 0),
      ], motion: true));
      // The controller starts in a post-frame callback, so the first pump only
      // schedules it. Sampling now would read the zeroth tick.
      await tester.pump();

      var rang = false;
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.byKey(const Key('trail_invite_ring')).evaluate().isNotEmpty) {
          rang = true;
        }
      }
      expect(rang, isTrue,
          reason: 'students never think to reopen the plan unless it says it '
              'is still there');

      // Hanging here is the failure: an endless ring makes every screen with a
      // trail untestable.
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('trail_invite_ring')), findsNothing,
          reason: 'an invitation that never stops stops being an invitation');
    });

    testWidgets('stays quiet on a node that does not ask', (tester) async {
      await tester.pumpWidget(_pump(_nodes(3, 1), motion: true));
      await tester.pump();

      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byKey(const Key('trail_invite_ring')), findsNothing);
      }
      await tester.pumpAndSettle();
    });
  });
}
