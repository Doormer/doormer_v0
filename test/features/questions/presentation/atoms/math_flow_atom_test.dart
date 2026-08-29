import 'package:doormer/src/features/questions/presentation/atoms/math_flow_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stand-in for a rendered clause: a known width, a known baseline, so the
/// layout can be measured exactly rather than inferred from real glyphs.
class _Block extends SingleChildRenderObjectWidget {
  final double width;
  final double height;
  final double baseline;

  const _Block(this.width, this.height, this.baseline, {super.key});

  @override
  _RenderBlock createRenderObject(BuildContext context) =>
      _RenderBlock(Size(width, height), baseline);
}

class _RenderBlock extends RenderBox {
  final Size preferred;
  final double baseline;

  _RenderBlock(this.preferred, this.baseline);

  @override
  void performLayout() => size = constraints.constrain(preferred);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      this.baseline;
}

Future<void> _pump(
  WidgetTester tester, {
  required double wrapWidth,
  required List<Widget> children,
  List<double> gaps = const [],
  double indent = 0,
  double runSpacing = 0,
}) {
  return tester.pumpWidget(MaterialApp(
    home: Align(
      alignment: Alignment.topLeft,
      child: MathFlowAtom(
        wrapWidth: wrapWidth,
        gaps: gaps,
        indent: indent,
        runSpacing: runSpacing,
        children: children,
      ),
    ),
  ));
}

Offset _at(WidgetTester tester, Key key) {
  final flow = tester.renderObject<RenderBox>(find.byType(MathFlowAtom));
  return tester
      .renderObject<RenderBox>(find.byKey(key))
      .localToGlobal(Offset.zero, ancestor: flow);
}

void main() {
  testWidgets('keeps clauses on one line while they fit', (tester) async {
    await _pump(
      tester,
      wrapWidth: 100,
      gaps: const [0, 4],
      children: const [
        _Block(40, 10, 10, key: Key('a')),
        _Block(40, 10, 10, key: Key('b')),
      ],
    );

    expect(_at(tester, const Key('a')), const Offset(0, 0));
    expect(_at(tester, const Key('b')), const Offset(44, 0));
    expect(tester.getSize(find.byType(MathFlowAtom)).height, 10);
  });

  testWidgets('spills onto a new line rather than running off the card',
      (tester) async {
    await _pump(
      tester,
      wrapWidth: 100,
      gaps: const [0, 4, 4],
      runSpacing: 6,
      children: const [
        _Block(40, 10, 10, key: Key('a')),
        _Block(40, 10, 10, key: Key('b')),
        _Block(40, 10, 10, key: Key('c')),
      ],
    );

    expect(_at(tester, const Key('c')).dy, 16,
        reason: 'the third clause drops to the next line');
    expect(tester.getSize(find.byType(MathFlowAtom)).width,
        lessThanOrEqualTo(100));
  });

  testWidgets('sets continuation lines in so a wrapped chain reads as one',
      (tester) async {
    await _pump(
      tester,
      wrapWidth: 100,
      indent: 12,
      children: const [
        _Block(60, 10, 10, key: Key('a')),
        _Block(60, 10, 10, key: Key('b')),
      ],
    );

    expect(_at(tester, const Key('a')).dx, 0);
    expect(_at(tester, const Key('b')).dx, 12);
  });

  testWidgets('drops the gap at the head of a line', (tester) async {
    // The gap stands for spacing between two clauses sitting side by side.
    // Kept when the line breaks, it would push the continuation past its
    // indent by an amount that depends on which relation happened to land
    // there.
    await _pump(
      tester,
      wrapWidth: 100,
      gaps: const [0, 30],
      indent: 12,
      children: const [
        _Block(60, 10, 10, key: Key('a')),
        _Block(60, 10, 10, key: Key('b')),
      ],
    );

    expect(_at(tester, const Key('b')).dx, 12);
  });

  testWidgets('sits clauses of different heights on a common baseline',
      (tester) async {
    // A fraction is taller than the equals sign beside it. Aligned any other
    // way, the equals sign floats off the line it belongs to.
    await _pump(
      tester,
      wrapWidth: 200,
      children: const [
        _Block(40, 30, 20, key: Key('tall')),
        _Block(40, 10, 6, key: Key('short')),
      ],
    );

    expect(_at(tester, const Key('tall')).dy + 20,
        _at(tester, const Key('short')).dy + 6);
  });

  testWidgets('is as tall as its lines and no taller', (tester) async {
    await _pump(
      tester,
      wrapWidth: 100,
      runSpacing: 6,
      children: const [
        _Block(60, 10, 10, key: Key('a')),
        _Block(60, 10, 10, key: Key('b')),
      ],
    );

    expect(tester.getSize(find.byType(MathFlowAtom)).height, 26,
        reason: 'two ten-high lines and one gap, with no gap left hanging '
            'under the last line');
  });

  testWidgets('reports the width a clause too wide to break needs',
      (tester) async {
    // This is what leaves the scroll view something to scroll: the one case
    // where wrapping cannot help.
    await _pump(
      tester,
      wrapWidth: 50,
      children: const [_Block(180, 10, 10, key: Key('a'))],
    );

    expect(tester.getSize(find.byType(MathFlowAtom)).width, 180);
  });

  testWidgets('lays out nothing without falling over', (tester) async {
    await _pump(tester, wrapWidth: 100, children: const []);
    expect(tester.getSize(find.byType(MathFlowAtom)), Size.zero);
  });
}
