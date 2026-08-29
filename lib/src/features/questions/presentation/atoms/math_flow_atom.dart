import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Lays a broken-up expression out as running maths: the clauses sit side by
/// side while they fit, and spill onto a new line when they do not.
///
/// [wrapWidth] is passed in rather than taken from the incoming constraints,
/// because this sits inside a horizontal scroll view — which offers infinite
/// width — and the whole point is to wrap at the width of the card instead.
/// The reported size may still exceed [wrapWidth] when a single clause is too
/// wide to break, and that is what leaves the scroll view something to scroll.
class MathFlowAtom extends MultiChildRenderObjectWidget {
  /// The width to break lines at, in pixels.
  final double wrapWidth;

  /// Space in front of each child, in pixels, when it shares a line with the
  /// one before it. Index-matched to [children]; the first entry is unused.
  final List<double> gaps;

  /// How far every line after the first is set in. Continuation lines are
  /// indented so that a wrapped chain reads as one argument carried on rather
  /// than as a second statement starting.
  final double indent;

  /// Space between lines.
  final double runSpacing;

  const MathFlowAtom({
    super.key,
    required this.wrapWidth,
    required this.gaps,
    required this.indent,
    required this.runSpacing,
    required super.children,
  });

  @override
  RenderMathFlow createRenderObject(BuildContext context) => RenderMathFlow(
        wrapWidth: wrapWidth,
        gaps: gaps,
        indent: indent,
        runSpacing: runSpacing,
      );

  @override
  void updateRenderObject(BuildContext context, RenderMathFlow renderObject) {
    renderObject
      ..wrapWidth = wrapWidth
      ..gaps = gaps
      ..indent = indent
      ..runSpacing = runSpacing;
  }
}

class MathFlowParentData extends ContainerBoxParentData<RenderBox> {}

class RenderMathFlow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MathFlowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MathFlowParentData> {
  RenderMathFlow({
    required double wrapWidth,
    required List<double> gaps,
    required double indent,
    required double runSpacing,
  })  : _wrapWidth = wrapWidth,
        _gaps = gaps,
        _indent = indent,
        _runSpacing = runSpacing;

  double _wrapWidth;
  double get wrapWidth => _wrapWidth;
  set wrapWidth(double value) {
    if (_wrapWidth == value) return;
    _wrapWidth = value;
    markNeedsLayout();
  }

  List<double> _gaps;
  List<double> get gaps => _gaps;
  set gaps(List<double> value) {
    if (listEquals(_gaps, value)) return;
    _gaps = value;
    markNeedsLayout();
  }

  double _indent;
  double get indent => _indent;
  set indent(double value) {
    if (_indent == value) return;
    _indent = value;
    markNeedsLayout();
  }

  double _runSpacing;
  double get runSpacing => _runSpacing;
  set runSpacing(double value) {
    if (_runSpacing == value) return;
    _runSpacing = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! MathFlowParentData) {
      child.parentData = MathFlowParentData();
    }
  }

  double _gapBefore(int index) => index < _gaps.length ? _gaps[index] : 0;

  /// Maths of different heights on one line must sit on a common baseline, or
  /// a fraction drags everything beside it off the line it belongs to.
  double _baselineOf(RenderBox child) =>
      child.getDistanceToBaseline(TextBaseline.alphabetic, onlyReal: true) ??
      child.size.height;

  @override
  void performLayout() {
    if (childCount == 0) {
      size = constraints.smallest;
      return;
    }

    final runs = <List<RenderBox>>[<RenderBox>[]];
    var cursor = 0.0;
    var widest = 0.0;
    var index = 0;

    for (var child = firstChild; child != null; child = childAfter(child)) {
      child.layout(const BoxConstraints(), parentUsesSize: true);
      final data = child.parentData! as MathFlowParentData;
      var run = runs.last;
      final opening = run.isEmpty;
      var start = opening
          ? (runs.length == 1 ? 0.0 : _indent)
          : cursor + _gapBefore(index);

      if (!opening && start + child.size.width > _wrapWidth) {
        widest = math.max(widest, cursor);
        run = <RenderBox>[];
        runs.add(run);
        start = _indent;
      }

      data.offset = Offset(start, 0);
      run.add(child);
      cursor = start + child.size.width;
      index++;
    }
    widest = math.max(widest, cursor);

    var top = 0.0;
    for (final run in runs) {
      var ascent = 0.0;
      var descent = 0.0;
      for (final child in run) {
        final baseline = _baselineOf(child);
        ascent = math.max(ascent, baseline);
        descent = math.max(descent, child.size.height - baseline);
      }
      for (final child in run) {
        final data = child.parentData! as MathFlowParentData;
        data.offset = Offset(data.offset.dx, top + ascent - _baselineOf(child));
      }
      top += ascent + descent + _runSpacing;
    }

    size = constraints.constrain(Size(widest, top - _runSpacing));
  }

  /// Only reached if an ancestor asks to be sized without laying out. Heights
  /// are approximate because baselines are not available without a real
  /// layout; the width — which is what decides the wrapping — is exact.
  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (childCount == 0) return constraints.smallest;

    var cursor = 0.0;
    var widest = 0.0;
    var top = 0.0;
    var tallest = 0.0;
    var opening = true;
    var index = 0;
    var firstRun = true;

    for (var child = firstChild; child != null; child = childAfter(child)) {
      final childSize = child.getDryLayout(const BoxConstraints());
      var start =
          opening ? (firstRun ? 0.0 : _indent) : cursor + _gapBefore(index);

      if (!opening && start + childSize.width > _wrapWidth) {
        widest = math.max(widest, cursor);
        top += tallest + _runSpacing;
        tallest = 0;
        firstRun = false;
        start = _indent;
      }

      tallest = math.max(tallest, childSize.height);
      cursor = start + childSize.width;
      opening = false;
      index++;
    }

    return constraints.constrain(Size(math.max(widest, cursor), top + tallest));
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final child = firstChild;
    if (child == null) return null;
    final data = child.parentData! as MathFlowParentData;
    final distance = child.getDistanceToActualBaseline(baseline);
    return distance == null ? null : distance + data.offset.dy;
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
