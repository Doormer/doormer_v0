import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/features/questions/presentation/atoms/edge_fade_atom.dart';
import 'package:doormer/src/features/questions/presentation/atoms/trail_connector_atom.dart';
import 'package:doormer/src/features/questions/presentation/molecules/trail_node_molecule.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_trail_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The node trail — the page's only progress indicator.
///
/// Three parts, not one strip: the briefing pinned at the head, the steps
/// panning between them, and the vault pinned at the tail. The bookends are
/// destinations rather than stops, and a destination that scrolls out of sight
/// stops being one — the student cannot see the answer they are working
/// towards, and never sees its chains break. So only the middle moves.
///
/// Nodes are a fixed size and the links between them stretch to take up the
/// slack. Sizing it the other way round — links fixed, nodes shrinking to fit —
/// turns the trail into a row of buttons: the circles crowd together and the
/// road between them disappears. The road is the part that reads as distance
/// travelled, so the road is the part that flexes.
///
/// Colour is the whole language: mint is banked, pink is here, dim is ahead,
/// amber is openable. A link lights mint only once the node behind it is done,
/// so the lit run always reads as ground already covered.
class SolutionTrailOrganism extends StatefulWidget {
  /// A numbered step you read. The bookends are deliberately larger, so both
  /// ends of the road read as somewhere to arrive rather than somewhere to
  /// pass through.
  static const double stepNodeSize = 30;
  static const double headNodeSize = 34;

  /// The vault is the biggest thing on the trail. It is the destination, and
  /// it is the only node carrying detail - three chains and a lock - so it
  /// needs the room. This costs nothing vertically: the bar is already as tall
  /// as a step node plus its padding.
  static const double tailNodeSize = 44;

  /// The road never shrinks below this, which is what makes the strip overflow
  /// and pan rather than squeezing itself into nothing.
  static const double minLinkWidth = 34;
  static const double linkMargin = 4;

  /// Clear air between a pinned bookend and the panning strip, so a node
  /// sliding under one is read as leaving rather than as touching it.
  static const double pinGap = 9;

  /// Breathing room inside the strip's own clip. The node the student is
  /// standing on glows well past its edge, and at either end of the pan that
  /// glow would otherwise be sliced off square against the clip.
  static const double stripPad = 26;

  /// The same room above and below. The strip has to clip horizontally, or
  /// panned-away nodes keep painting and slide out under the pinned bookends —
  /// but a clip cuts all four sides, and the glow is wider than the bar is
  /// tall. So the strip overflows its slot vertically: the glow gets its room
  /// inside the clip, and the bar's height never changes.
  static const double glowRoom = 26;

  final List<SolutionTrailNode> nodes;

  /// Called with a node's [SolutionTrailNode.travelTo] when the student taps
  /// it. A null callback disables travel.
  final void Function(int position)? onNodeTap;

  const SolutionTrailOrganism({
    super.key,
    required this.nodes,
    this.onNodeTap,
  });

  @override
  State<SolutionTrailOrganism> createState() => _SolutionTrailOrganismState();
}

class _SolutionTrailOrganismState extends State<SolutionTrailOrganism> {
  final ScrollController _controller = ScrollController();

  /// Node-to-node distance inside the panning strip, settled by the last
  /// layout. [_centreCurrent] needs it and cannot ask the render tree, so
  /// layout hands it over.
  double _stride = SolutionTrailOrganism.stepNodeSize +
      SolutionTrailOrganism.minLinkWidth +
      SolutionTrailOrganism.linkMargin * 2;

  bool _moreLeft = false;
  bool _moreRight = false;

  /// Where the panning strip starts in [SolutionTrailOrganism.nodes] — 1 when
  /// a bookend has been lifted out to be pinned, 0 when there is none.
  int get _stepOffset => _hasHead ? 1 : 0;

  bool get _hasHead =>
      widget.nodes.isNotEmpty &&
      widget.nodes.first.shape == SolutionTrailNodeShape.marker;

  bool get _hasTail =>
      widget.nodes.length > 1 &&
      widget.nodes.last.shape == SolutionTrailNodeShape.marker;

  List<SolutionTrailNode> get _steps => widget.nodes.sublist(
        _stepOffset,
        _hasTail ? widget.nodes.length - 1 : widget.nodes.length,
      );

  /// The current node's place in the panning strip, or -1 when the student is
  /// standing on a pinned bookend and there is nothing to pan to.
  int get _currentIndex =>
      _steps.indexWhere((n) => n.state == SolutionTrailNodeState.current);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncEdges);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncEdges());
  }

  @override
  void didUpdateWidget(SolutionTrailOrganism oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousSteps = oldWidget.nodes
        .where((n) => n.shape == SolutionTrailNodeShape.step)
        .toList();
    final previous = previousSteps
        .indexWhere((n) => n.state == SolutionTrailNodeState.current);
    if (previous != _currentIndex ||
        oldWidget.nodes.length != widget.nodes.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centreCurrent();
        _syncEdges();
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_syncEdges);
    _controller.dispose();
    super.dispose();
  }

  /// Fades whichever edge has trail beyond it, so a strip that runs off the
  /// screen says so rather than looking like it simply ends there.
  void _syncEdges() {
    if (!mounted || !_controller.hasClients) return;
    final position = _controller.position;
    final left = position.extentBefore > 1;
    final right = position.extentAfter > 1;
    if (left == _moreLeft && right == _moreRight) return;
    setState(() {
      _moreLeft = left;
      _moreRight = right;
    });
  }

  /// Brings the current node to the middle of the strip.
  ///
  /// Once the trail is longer than the screen the current node drifts off the
  /// end and the student loses the one indicator of where they are, so the
  /// strip follows them. Computed from layout arithmetic rather than measured
  /// from render boxes, because the node it needs to measure is mid-animation.
  void _centreCurrent() {
    if (!mounted || !_controller.hasClients) return;
    final index = _currentIndex;
    if (index < 0) return;

    const nodeSize = SolutionTrailOrganism.stepNodeSize;
    final centre =
        SolutionTrailOrganism.stripPad + index * _stride + nodeSize / 2;
    final target = centre - _controller.position.viewportDimension / 2;
    final clamped = target.clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );

    if ((clamped - _controller.offset).abs() < 1) return;

    final duration = MotionPolicy.duration(
      context,
      const Duration(milliseconds: 420),
    );
    if (duration == Duration.zero) {
      _controller.jumpTo(clamped);
      return;
    }
    _controller.animateTo(clamped,
        duration: duration, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final nodes = widget.nodes;
    if (nodes.isEmpty) return const SizedBox.shrink();

    final hasHead = _hasHead;
    final hasTail = _hasTail;

    return Row(
      children: [
        if (hasHead) ...[
          TrailNodeMolecule(
            index: 0,
            node: nodes.first,
            size: SolutionTrailOrganism.headNodeSize,
            onTap: _tapFor(0),
          ),
          const SizedBox(width: SolutionTrailOrganism.pinGap),
        ],
        Expanded(child: _panningStrip()),
        if (hasTail) ...[
          const SizedBox(width: SolutionTrailOrganism.pinGap),
          TrailNodeMolecule(
            index: nodes.length - 1,
            node: nodes.last,
            size: SolutionTrailOrganism.tailNodeSize,
            onTap: _tapFor(nodes.length - 1),
          ),
        ],
      ],
    );
  }

  /// The only part of the trail that moves.
  Widget _panningStrip() {
    final steps = _steps;
    final offset = _stepOffset;

    return LayoutBuilder(
      builder: (context, constraints) {
        const nodeSize = SolutionTrailOrganism.stepNodeSize;
        const margin = SolutionTrailOrganism.linkMargin;
        const minLink = SolutionTrailOrganism.minLinkWidth;

        // Links take the slack when there is any, and hold their minimum when
        // there is not — which is the point at which the strip starts panning.
        final gaps = steps.length - 1;
        final slack = constraints.maxWidth -
            SolutionTrailOrganism.stripPad * 2 -
            steps.length * nodeSize -
            gaps * margin * 2;
        final linkWidth =
            gaps > 0 && slack / gaps > minLink ? slack / gaps : minLink;
        _stride = nodeSize + linkWidth + margin * 2;

        const room = SolutionTrailOrganism.glowRoom;
        final barHeight = nodeSize + 14.h;

        return SizedBox(
          height: barHeight,
          child: OverflowBox(
            minHeight: barHeight + room * 2,
            maxHeight: barHeight + room * 2,
            child: EdgeFadeAtom(
              left: _moreLeft,
              right: _moreRight,
              child: SingleChildScrollView(
                key: const Key('solution_trail_scroll'),
                controller: _controller,
                scrollDirection: Axis.horizontal,
                // The current node is scaled up and glows past its own box; without
                // the padding the clip cuts the glow off mid-halo.
                padding: const EdgeInsets.symmetric(
                  horizontal: SolutionTrailOrganism.stripPad,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < steps.length; i++) ...[
                      TrailNodeMolecule(
                        index: offset + i,
                        node: steps[i],
                        size: nodeSize,
                        onTap: _tapFor(offset + i),
                      ),
                      if (i < steps.length - 1)
                        TrailConnectorAtom(
                          index: i,
                          width: linkWidth,
                          margin: margin,
                          lit: steps[i].state == SolutionTrailNodeState.done,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Only ground already covered is travellable, and the presenter decides
  /// which ground that is — offering an upcoming node would let the student
  /// skip the working the page exists to teach.
  VoidCallback? _tapFor(int index) {
    final onNodeTap = widget.onNodeTap;
    final travelTo = widget.nodes[index].travelTo;
    if (onNodeTap == null || travelTo == null) return null;
    return () => onNodeTap(travelTo);
  }
}
