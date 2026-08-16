import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/molecules/solution_trail_molecule.dart';
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
      ),
  ];
}

Widget _pump(List<SolutionTrailNode> nodes, {double width = 358}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: SolutionTrailMolecule(nodes: nodes),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders one node per step with a tick on completed steps',
      (tester) async {
    await tester.pumpWidget(_pump(_nodes(3, 1)));
    await tester.pump();

    expect(find.byKey(const Key('trail_node_0')), findsOneWidget);
    expect(find.byKey(const Key('trail_node_1')), findsOneWidget);
    expect(find.byKey(const Key('trail_node_2')), findsOneWidget);

    expect(find.byIcon(Icons.check), findsOneWidget);
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

  testWidgets('an icon node still shows the tick once it is done',
      (tester) async {
    await tester.pumpWidget(_pump(const [
      SolutionTrailNode(
        displayNumber: 0,
        state: SolutionTrailNodeState.done,
        semanticsLabel: 'The plan',
        icon: Icons.flag_outlined,
      ),
    ]));
    await tester.pump();

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.flag_outlined), findsNothing);
  });
}
