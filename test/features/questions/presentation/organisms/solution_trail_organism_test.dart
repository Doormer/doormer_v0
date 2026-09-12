import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_trail_organism.dart';
import 'package:doormer/src/features/questions/presentation/atoms/trail_connector_atom.dart';
import 'package:doormer/src/features/questions/presentation/molecules/trail_node_molecule.dart';
import 'package:doormer/src/features/questions/presentation/atoms/vault_chains_atom.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_trail_node.dart';
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

/// A trail with both bookends: the plan at the head, the vault at the tail.
List<SolutionTrailNode> _bookended(int stepCount, int currentIndex) => [
      const SolutionTrailNode(
        displayNumber: 0,
        state: SolutionTrailNodeState.done,
        semanticsLabel: 'The plan',
        icon: Icons.flag_rounded,
        shape: SolutionTrailNodeShape.marker,
        travelTo: SolutionTrailNode.briefingPosition,
      ),
      ..._nodes(stepCount, currentIndex),
      const SolutionTrailNode(
        displayNumber: 0,
        state: SolutionTrailNodeState.upcoming,
        semanticsLabel: 'The answer, locked',
        icon: Icons.lock_rounded,
        shape: SolutionTrailNodeShape.marker,
      ),
    ];

Widget _pump(
  List<SolutionTrailNode> nodes, {
  double? width = 358,
  double? height,
  Axis axis = Axis.horizontal,
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
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              height: height,
              child: SolutionTrailOrganism(
                nodes: nodes,
                onNodeTap: onNodeTap,
                axis: axis,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  _chainTests();
  _vaultLooksLikeMetalTests();
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

  testWidgets('holds every step node at one size however many there are',
      (tester) async {
    // Nine steps in 200px is far more road than there is room for. The links
    // are what give way; if the nodes shrink instead, the trail stops reading
    // as a road and becomes a row of buttons.
    await tester.pumpWidget(_pump(_nodes(9, 0), width: 200));
    await tester.pump();

    for (var i = 0; i < 9; i++) {
      final size = tester.getSize(find.byKey(Key('trail_node_$i')));
      expect(
        size.width,
        closeTo(SolutionTrailOrganism.stepNodeSize, 0.5),
        reason: 'node $i was squeezed to fit instead of the link giving way',
      );
    }
  });

  testWidgets('leaves more road than node between two steps', (tester) async {
    await tester.pumpWidget(_pump(_nodes(9, 0), width: 200));
    await tester.pump();

    final a = tester.getTopLeft(find.byKey(const Key('trail_node_0')));
    final b = tester.getTopLeft(find.byKey(const Key('trail_node_1')));
    expect(
      b.dx - a.dx - SolutionTrailOrganism.stepNodeSize,
      greaterThan(SolutionTrailOrganism.stepNodeSize),
      reason: 'the distance travelled should out-measure the stop',
    );
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

  group('as a rail', _railTests);
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
  testWidgets(
      'brings the current node back into view when it moves past the end',
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

    final nodeCentre =
        tester.getCenter(find.byKey(const Key('trail_node_9'))).dx;
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

int _chains(WidgetTester tester) => List.generate(
      3,
      (i) => find.byKey(Key('vault_chain_$i')),
    ).where((f) => f.evaluate().isNotEmpty).length;

void _chainTests() {
  group('the vault chains', () {
    testWidgets('lash the vault shut before any working is done',
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

    testWidgets('leave the chain wrapped behind the lock till last',
        (tester) async {
      await tester.pumpWidget(_pump(_withVault(2)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('vault_chain_2')), findsOneWidget,
          reason: 'one chain left should still read as wrapped around the '
              'box, not as an underline beneath it');
      expect(find.byKey(const Key('vault_chain_0')), findsNothing);
      expect(find.byKey(const Key('vault_chain_1')), findsNothing);
      final middle = vaultChainSegments(index: 2, phase: 0).single;
      expect(middle.start.dy, 0,
          reason: 'the chain left standing has to be the one across the lock, '
              'not one of the plain runs above or below it');
    });

    testWidgets('run behind the lock rather than stopping either side of it',
        (tester) async {
      await tester.pumpWidget(_pump(_withVault(2)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_rounded), findsOneWidget,
          reason: 'the lock moved out of the box so the chain could be laid '
              'between the two. Left in the box as well it is painted twice, '
              'once under the chain and once over, and the one underneath is '
              'the one a future change will start drawing');

      final stack = tester.widget<Stack>(find
          .ancestor(
            of: find.byKey(const Key('vault_lock')),
            matching: find.byType(Stack),
          )
          .first);
      final lock =
          stack.children.indexWhere((w) => w.key == const Key('vault_lock'));
      final chain =
          stack.children.indexWhere((w) => w.key == const Key('vault_chain_2'));

      expect(chain, isNonNegative);
      expect(lock, greaterThan(chain),
          reason: 'the chain runs straight across the lock, so the lock has to '
              'be painted over it. Underneath, the lock is struck through by '
              'the very thing holding it shut, which reads as a wrong answer');
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

  testWidgets('keeps the plan and the vault in place while the steps pan',
      (tester) async {
    const tail = 8;
    await tester.pumpWidget(_pump(_bookended(7, 0), width: 358));
    await tester.pumpAndSettle();

    final headBefore = tester.getTopLeft(find.byKey(const Key('trail_node_0')));
    final tailBefore =
        tester.getTopLeft(find.byKey(const Key('trail_node_$tail')));
    final stepBefore = tester.getTopLeft(find.byKey(const Key('trail_node_6')));

    await tester.pumpWidget(_pump(_bookended(7, 6), width: 358));
    await tester.pumpAndSettle();

    // The strip really did move -- without this the test would pass on a trail
    // that never pans at all, and prove nothing.
    expect(
      tester.getTopLeft(find.byKey(const Key('trail_node_6'))).dx,
      isNot(closeTo(stepBefore.dx, 1)),
      reason: 'the steps should have panned to follow the student',
    );

    expect(
      tester.getTopLeft(find.byKey(const Key('trail_node_0'))).dx,
      closeTo(headBefore.dx, 0.5),
      reason: 'the way back to the plan must not slide off the head',
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('trail_node_$tail'))).dx,
      closeTo(tailBefore.dx, 0.5),
      reason: 'the destination has to stay in sight the whole way',
    );
  });

  testWidgets('shows the locked vault from the very first screen',
      (tester) async {
    await tester.pumpWidget(_pump(_bookended(7, 0), width: 358));
    await tester.pumpAndSettle();

    // Its chains break as the working is done. A vault parked off the right
    // edge means no student ever sees that happen.
    final rect = tester.getRect(find.byKey(const Key('trail_node_8')));
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(358));
  });

  testWidgets('lights the road behind the student and leaves the rest dark',
      (tester) async {
    await tester.pumpWidget(_pump(_nodes(4, 2), width: 358));
    await tester.pumpAndSettle();

    // Steps 1 and 2 are behind them, so those two stretches are covered ground.
    for (final lit in [0, 1]) {
      expect(
        tester.getSize(find.byKey(Key('trail_link_fill_$lit'))).width,
        greaterThan(1),
        reason: 'the road out of a finished step should read as travelled',
      );
    }
    expect(
      tester.getSize(find.byKey(const Key('trail_link_fill_2'))).width,
      lessThan(1),
      reason: 'the road ahead has not been walked yet',
    );
  });

  testWidgets('outlines the bookends instead of filling them like a step',
      (tester) async {
    await tester.pumpWidget(_pump(_bookended(3, 1), width: 358));
    await tester.pumpAndSettle();

    BoxDecoration decoration(String key) =>
        tester.widget<Container>(find.byKey(Key(key))).decoration!
            as BoxDecoration;

    // Step 1 is banked, and a banked step is a solid mint disc.
    expect(decoration('trail_node_1').color!.a, closeTo(1, 0.01));

    // The plan sits behind them too, but it is not a step they earned. Filling
    // it the same way says 'step zero, complete'.
    expect(
      decoration('trail_node_0').color!.a,
      lessThan(0.5),
      reason: 'the plan should read as a place to return to, not a trophy',
    );
    expect(decoration('trail_node_0').border, isNotNull);
  });

  testWidgets('gives the glow room to spill without making the bar taller',
      (tester) async {
    await tester.pumpWidget(_pump(_bookended(7, 3), width: 358));
    await tester.pumpAndSettle();

    final bar = tester.getSize(find.byType(SolutionTrailOrganism)).height;
    final strip =
        tester.getSize(find.byKey(const Key('solution_trail_scroll'))).height;

    // The strip has to clip horizontally, and a clip cuts all four sides. If
    // it is only as tall as the bar, the current node's glow comes out as a
    // bright rectangle with three square corners.
    expect(
      strip,
      greaterThan(bar + SolutionTrailOrganism.glowRoom),
      reason: 'the glow has nowhere to go and will be sliced off square',
    );

    // ...and none of that room is allowed to push the question down the page.
    expect(
      bar,
      lessThan(SolutionTrailOrganism.tailNodeSize + 8),
      reason: 'the breathing room leaked into the layout',
    );
  });
}

void _vaultLooksLikeMetalTests() {
  group('the vault', () {
    testWidgets('is the biggest thing on the trail', (tester) async {
      await tester.pumpWidget(_pump(_bookended(4, 1)));
      await tester.pumpAndSettle();

      final vault = tester.getSize(find.byKey(const Key('trail_node_5')));
      final plan = tester.getSize(find.byKey(const Key('trail_node_0')));
      final step = tester.getSize(find.byKey(const Key('trail_node_2')));

      expect(vault.width, greaterThan(plan.width),
          reason: 'the vault is where the student is going, and it is the only '
              'node carrying detail - a chain and a lock. Sized like the plan '
              'it has no room for either and the links turn to mush');
      expect(vault.width, greaterThan(step.width));
    });

    test('fills every run with links rather than one long bar', () {
      // A run drawn as one stretched link is a bar with rounded ends -- exactly
      // the thing the chain replaced. What reads as chain is a repeat, and a
      // repeat needs a count.
      for (var i = 0; i < 3; i++) {
        for (final run in vaultChainSegments(index: i, phase: 0)) {
          final length = (run.end - run.start).distance;
          expect(vaultChainLinkCount(length), greaterThanOrEqualTo(2),
              reason: 'chain \$i has a run too short to hold two links, so it '
                  'draws as a lone oval');
        }
      }

      final across = vaultChainSegments(index: 0, phase: 0).single;
      expect(vaultChainLinkCount((across.end - across.start).distance),
          greaterThanOrEqualTo(6),
          reason: 'a chain across the whole vault needs enough links that the '
              'alternation is visible, not three fat ovals');
    });

    test('turns every other link edge-on so the run reads as chain', () {
      final face = vaultChainLinkHeight(0);
      final edge = vaultChainLinkHeight(1);

      expect(vaultChainLinkHeight(2), face, reason: 'the turn has to repeat');
      expect(edge, lessThan(face * 0.6),
          reason:
              'links all one width are beads on a string. It is the turn of '
              'every second link that says chain, because at this size the hole '
              'through a link is too small to say it');
    });

    test('lights the links from above so they read as metal', () {
      final shades = vaultChainShades();

      expect(shades, hasLength(4));
      var previous = shades.first.computeLuminance();
      for (final shade in shades.skip(1)) {
        expect(shade.computeLuminance(), lessThan(previous),
            reason: 'a link shaded flat, or lit from below, reads as chain '
                'drawn on the vault rather than chain lying across it');
        previous = shade.computeLuminance();
      }
      // Range alone is not enough: a link with a dark underside but no lit
      // edge still spans a wide range while looking flat on top.
      // Measured against the link's own body rather than a palette colour, so
      // the guard still holds if the whole chain is re-pitched lighter or
      // darker.
      expect(shades.first.computeLuminance() - shades[1].computeLuminance(),
          greaterThan(0.12),
          reason: 'without a lit top edge the wire has no roundness');
      expect(shades[1].computeLuminance() - shades.last.computeLuminance(),
          greaterThan(0.12),
          reason: 'without a shaded underside the wire has no thickness');
    });
  });
}

/// The vertical form: on a window wide enough to spare the width, the trail
/// runs down the side of the reader instead of across the top of it, which
/// buys back the height a short laptop window has least of.
void _railTests() {

  // Found by position rather than by what a node displays: a step already read
  // shows a check instead of its number, and a node with nowhere to travel
  // carries no tap key at all. Tree order is head, steps, tail -- the order the
  // road runs in.
  Finder nodeAt(int index) => find.byType(TrailNodeMolecule).at(index);

  testWidgets('keeps the vault at the end of the road, not the end of the box',
      (tester) async {
    // Far more height than seven steps need: the road must hug its own length
    // rather than spreading to fill whatever it is given. The surface has to be
    // grown too -- the default 600px one cannot hold the surplus that makes
    // this test mean anything.
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_pump(
      _bookended(7, 0),
      width: null,
      height: 1100,
      axis: Axis.vertical,
    ));
    await tester.pump();

    final lastStep = tester.getRect(nodeAt(7));
    final vault = tester.getRect(nodeAt(8));

    expect(
      vault.top - lastStep.bottom,
      lessThan(SolutionTrailOrganism.stripPad * 2 +
          SolutionTrailOrganism.pinGap +
          1),
      reason: 'a gap the height of a card reads as a mistake, not a pin',
    );
  });

  testWidgets('runs down the screen rather than across it', (tester) async {
    await tester.pumpWidget(_pump(
      _nodes(3, 0),
      width: 120,
      height: 500,
      axis: Axis.vertical,
    ));
    await tester.pump();

    final first = tester.getCenter(nodeAt(0));
    final second = tester.getCenter(nodeAt(1));
    final third = tester.getCenter(nodeAt(2));

    expect(second.dy, greaterThan(first.dy));
    expect(third.dy, greaterThan(second.dy));
    expect(second.dx, moreOrLessEquals(first.dx, epsilon: 0.5),
        reason: 'the road is a straight line down, not a staircase');
  });

  testWidgets('claims only the width a node needs, leaving the rest to read',
      (tester) async {
    await tester.pumpWidget(_pump(
      _bookended(3, 0),
      // Deliberately unforced: the rail has to settle its own width, which is
      // the whole question here.
      width: null,
      height: 600,
      axis: Axis.vertical,
    ));
    await tester.pump();

    final rail = tester.getSize(find.byType(SolutionTrailOrganism));
    expect(rail.width, lessThanOrEqualTo(SolutionTrailOrganism.tailNodeSize),
        reason: 'a rail wider than its widest node is stealing reading width');
  });

  testWidgets('starts at the top instead of stretching to fill the height',
      (tester) async {
    await tester.pumpWidget(_pump(
      _bookended(3, 0),
      width: 120,
      height: 800,
      axis: Axis.vertical,
    ));
    await tester.pump();

    final rail = tester.getSize(find.byType(SolutionTrailOrganism));
    expect(rail.height, lessThan(800),
        reason: 'a short trail in a tall window must not stretch to fit it');

    // The road holds its normal spacing rather than pulling the nodes apart.
    final first = tester.getCenter(nodeAt(1));
    final second = tester.getCenter(nodeAt(2));
    expect(
      second.dy - first.dy,
      moreOrLessEquals(
        SolutionTrailOrganism.stepNodeSize +
            SolutionTrailOrganism.minLinkWidth +
            SolutionTrailOrganism.linkMargin * 2,
        epsilon: 1,
      ),
    );
  });

  testWidgets('bookends the road top and bottom', (tester) async {
    await tester.pumpWidget(_pump(
      _bookended(3, 0),
      width: 120,
      height: 600,
      axis: Axis.vertical,
    ));
    await tester.pump();

    final plan = tester.getCenter(find.byIcon(Icons.flag_rounded));
    final vault = tester.getCenter(find.byIcon(Icons.lock_rounded));
    final firstStep = tester.getCenter(nodeAt(1));

    expect(plan.dy, lessThan(firstStep.dy), reason: 'the plan is where you start');
    expect(vault.dy, greaterThan(firstStep.dy),
        reason: 'the vault is where you are going');
  });

  testWidgets('draws its links down the trail, not across it', (tester) async {
    await tester.pumpWidget(_pump(
      _nodes(3, 0),
      width: 120,
      height: 500,
      axis: Axis.vertical,
    ));
    await tester.pump();

    final link = tester.getSize(find.byType(TrailConnectorAtom).first);
    expect(link.height, greaterThan(link.width),
        reason: 'a run of road down a rail is taller than it is wide');
  });

  testWidgets('pans to keep the current node in view on a short rail',
      (tester) async {
    await tester.pumpWidget(_pump(
      _nodes(12, 0),
      width: 120,
      height: 260,
      axis: Axis.vertical,
    ));
    await tester.pumpAndSettle();

    final scroll = find.byKey(const Key('solution_trail_scroll'));
    final atStart =
        tester.widget<SingleChildScrollView>(scroll).controller!.offset;

    await tester.pumpWidget(_pump(
      _nodes(12, 9),
      width: 120,
      height: 260,
      axis: Axis.vertical,
    ));
    await tester.pumpAndSettle();

    final atStepTen =
        tester.widget<SingleChildScrollView>(scroll).controller!.offset;
    expect(atStepTen, greaterThan(atStart),
        reason: 'the rail follows the student down the road');
  });

  testWidgets('scrolls down the rail, so a long road is reachable',
      (tester) async {
    await tester.pumpWidget(_pump(
      _nodes(12, 0),
      width: 120,
      height: 260,
      axis: Axis.vertical,
    ));
    await tester.pump();

    final scroll = tester.widget<SingleChildScrollView>(
      find.byKey(const Key('solution_trail_scroll')),
    );
    expect(scroll.scrollDirection, Axis.vertical);
  });

  testWidgets('still travels when a covered node is tapped', (tester) async {
    final travelled = <int>[];
    await tester.pumpWidget(_pump(
      _nodes(4, 2),
      width: 120,
      height: 500,
      axis: Axis.vertical,
      onNodeTap: travelled.add,
    ));
    await tester.pump();

    await tester.tap(nodeAt(0));
    await tester.pump();

    expect(travelled, [0]);
  });
}
