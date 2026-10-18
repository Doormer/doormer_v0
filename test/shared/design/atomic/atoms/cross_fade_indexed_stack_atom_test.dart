import 'package:doormer/src/shared/design/atomic/atoms/cross_fade_indexed_stack_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _fade = CrossFadeIndexedStackAtom.duration;
// A fade ends on the first frame after its duration.
const _frame = Duration(milliseconds: 16);
const _names = ['Saved', 'Solve', 'Cards'];

/// Fills the stack and counts its taps in its state, so a test can tell a
/// kept page from one built afresh.
class _Page extends StatefulWidget {
  final String name;

  const _Page(this.name, {super.key});

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  int taps = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => taps++,
      child: SizedBox.expand(child: Center(child: Text(widget.name))),
    );
  }
}

Future<void> _show(
  WidgetTester tester,
  int index, {
  bool motion = true,
  List<String> names = _names,
}) {
  return tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: !motion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: CrossFadeIndexedStackAtom(
          index: index,
          children: [
            for (final name in names) _Page(name, key: ValueKey(name)),
          ],
        ),
      ),
    ),
  );
}

double _opacityOf(WidgetTester tester, String name) {
  final fade = find.ancestor(
    of: find.text(name, skipOffstage: false),
    matching: find.byType(FadeTransition, skipOffstage: false),
  );
  return tester.widget<FadeTransition>(fade.first).opacity.value;
}

int _tapsOf(WidgetTester tester, String name) => tester
    .state<_PageState>(find.byKey(ValueKey(name), skipOffstage: false))
    .taps;

bool _ticking(WidgetTester tester, String name) =>
    TickerMode.of(tester.element(find.text(name, skipOffstage: false)));

void main() {
  testWidgets('shows the child at index, keeping the others out of sight',
      (tester) async {
    await _show(tester, 1);

    expect(find.text('Solve'), findsOneWidget);
    expect(find.text('Saved'), findsNothing);
    expect(find.text('Cards'), findsNothing);
    expect(find.text('Saved', skipOffstage: false), findsOneWidget,
        reason: 'kept, not dropped');
  });

  testWidgets('the first child shows at once, with no fade', (tester) async {
    await _show(tester, 1);

    expect(_opacityOf(tester, 'Solve'), 1.0);
  });

  testWidgets(
      'a child that comes back after the list got shorter stays out of sight',
      (tester) async {
    await _show(tester, 2);
    await _show(tester, 0);
    await tester.pump(_fade ~/ 2);

    await _show(tester, 0, names: _names.take(2).toList());
    await _show(tester, 0);
    await tester.pump(_frame);

    expect(find.text('Cards'), findsNothing);
    expect(_ticking(tester, 'Cards'), isFalse);
  });

  // Like closing the open tab: the child on screen goes in the same update
  // that switches away from it.
  testWidgets(
      'a child removed as it is switched away from stays out of sight when '
      'it comes back', (tester) async {
    await _show(tester, 2);
    await _show(tester, 0, names: _names.take(2).toList());
    await tester.pump(_fade + _frame);

    await _show(tester, 0);
    await tester.pump(_frame);

    expect(find.text('Cards'), findsNothing);
    expect(_ticking(tester, 'Cards'), isFalse);
  });

  testWidgets('a switch fades the old child out as the new one fades in',
      (tester) async {
    await _show(tester, 0);
    await _show(tester, 1);
    await tester.pump(_fade ~/ 2);

    expect(find.text('Saved'), findsOneWidget, reason: 'still fading out');
    expect(find.text('Solve'), findsOneWidget);
    final saved = _opacityOf(tester, 'Saved');
    final solve = _opacityOf(tester, 'Solve');
    expect(saved, inExclusiveRange(0, 1));
    expect(solve, inExclusiveRange(0, 1));
    expect(saved + solve, moreOrLessEquals(1),
        reason: 'both at once, on the same curve');
  });

  testWidgets('once faded, the old child is out of sight, with its state kept',
      (tester) async {
    await _show(tester, 0);
    await tester.tap(find.text('Saved'));
    await _show(tester, 1);
    await tester.pump(_fade + _frame);

    expect(find.text('Saved'), findsNothing);
    expect(_opacityOf(tester, 'Solve'), 1.0);

    await _show(tester, 0);
    await tester.pump(_fade + _frame);
    expect(_tapsOf(tester, 'Saved'), 1, reason: 'the same page, not a new one');
  });

  testWidgets('mid-fade, taps go to the new child only', (tester) async {
    // Solve comes after Saved, so it is painted on top while it fades out.
    await _show(tester, 1);
    await _show(tester, 0);
    await tester.pump(_fade ~/ 2);

    await tester
        .tapAt(tester.getCenter(find.byType(CrossFadeIndexedStackAtom)));

    expect(_tapsOf(tester, 'Saved'), 1);
    expect(_tapsOf(tester, 'Solve'), 0);
  });

  testWidgets('mid-fade, screen readers only hear the new child',
      (tester) async {
    final semantics = tester.ensureSemantics();
    // What a screen reader can move through, in order.
    Iterable<String> heard() => tester.semantics
        .simulatedAccessibilityTraversal()
        .map((node) => node.label);
    await _show(tester, 1);
    await _show(tester, 0);
    await tester.pump(_fade ~/ 2);

    expect(heard(), contains(contains('Saved')));
    expect(heard(), isNot(contains(contains('Solve'))));
    semantics.dispose();
  });

  testWidgets('the old child keeps its animations until it has faded out',
      (tester) async {
    await _show(tester, 0);
    expect(_ticking(tester, 'Saved'), isTrue);
    expect(_ticking(tester, 'Solve'), isFalse, reason: 'out of sight');

    await _show(tester, 1);
    await tester.pump(_fade ~/ 2);
    expect(_ticking(tester, 'Saved'), isTrue, reason: 'still on screen');
    expect(_ticking(tester, 'Solve'), isTrue);

    await tester.pump(_fade ~/ 2 + _frame);
    expect(_ticking(tester, 'Saved'), isFalse);
  });

  testWidgets('a switch mid-fade carries each child on from where it is',
      (tester) async {
    await _show(tester, 0);
    await _show(tester, 1);
    await tester.pump(_fade ~/ 2);
    final solve = _opacityOf(tester, 'Solve');

    await _show(tester, 2);
    expect(find.text('Saved'), findsOneWidget, reason: 'still fading out');
    expect(_opacityOf(tester, 'Solve'), moreOrLessEquals(solve),
        reason: 'no jump');

    await tester.pump(_fade ~/ 2);
    expect(_opacityOf(tester, 'Solve'), lessThan(solve));
    expect(_opacityOf(tester, 'Cards'), greaterThan(0));

    await tester.pump(_fade ~/ 2 + _frame);
    expect(find.text('Saved'), findsNothing);
    expect(find.text('Solve'), findsNothing);
    expect(_opacityOf(tester, 'Cards'), 1.0);
  });

  testWidgets('switching back mid-fade turns round without a jump',
      (tester) async {
    await _show(tester, 0);
    await _show(tester, 1);
    await tester.pump(_fade ~/ 2);
    final saved = _opacityOf(tester, 'Saved');

    await _show(tester, 0);
    expect(find.text('Solve'), findsOneWidget, reason: 'now fading out');
    expect(_opacityOf(tester, 'Saved'), moreOrLessEquals(saved));

    await tester.pump(_fade + _frame);
    expect(_opacityOf(tester, 'Saved'), 1.0);
    expect(find.text('Solve'), findsNothing);
  });

  testWidgets('with motion off, a switch is instant', (tester) async {
    await _show(tester, 0, motion: false);
    await _show(tester, 1, motion: false);

    expect(find.text('Saved'), findsNothing);
    expect(find.text('Solve'), findsOneWidget);
    expect(_opacityOf(tester, 'Solve'), 1.0);
  });
}
