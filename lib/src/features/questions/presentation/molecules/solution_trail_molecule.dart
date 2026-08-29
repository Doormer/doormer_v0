import 'dart:math' as math;
import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/idle_beat_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The four things a trail node can be.
///
/// [ready] exists only for the vault: amber means "you can open this now",
/// which is a different promise from [current] ("you are reading this"). Using
/// pink for both would tell the student they are in two places at once.
enum SolutionTrailNodeState { done, current, upcoming, ready }

/// Round nodes are steps you read. Square nodes are the two destinations that
/// bookend the trail, so both ends look like places rather than stops.
enum SolutionTrailNodeShape { step, marker }

class SolutionTrailNode {
  final int displayNumber;
  final SolutionTrailNodeState state;
  final String semanticsLabel;

  /// Drawn instead of [displayNumber] on a node that is not a numbered step,
  /// such as the briefing at the head of the trail. Step nodes leave this null
  /// so their numbering never shifts.
  final IconData? icon;

  final SolutionTrailNodeShape shape;

  /// The trail position tapping this node returns the student to:
  /// [SolutionTrailMolecule.briefingPosition] for the briefing at the head,
  /// otherwise a zero-based step index.
  ///
  /// Null on any node that is not a place they can go — the road ahead, and
  /// the vault, which is a destination rather than a stop.
  final int? travelTo;

  /// How many of the three chains strapped across this node have already been
  /// broken. Null on every node that is not the vault — the briefing marker
  /// was never locked, so it was never chained.
  final int? chainsBroken;

  /// Whether this node should ring a few times to say it can be returned to.
  /// The plan at the head of the trail is the one thing students never think
  /// to go back to, so it is the one thing that asks.
  final bool invites;

  const SolutionTrailNode({
    required this.displayNumber,
    required this.state,
    required this.semanticsLabel,
    this.icon,
    this.shape = SolutionTrailNodeShape.step,
    this.travelTo,
    this.chainsBroken,
    this.invites = false,
  });
}

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
class SolutionTrailMolecule extends StatefulWidget {
  /// A numbered step you read. The bookends are deliberately larger, so both
  /// ends of the road read as somewhere to arrive rather than somewhere to
  /// pass through.
  static const double stepNodeSize = 30;
  static const double headNodeSize = 34;
  static const double tailNodeSize = 38;

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

  /// The briefing sits ahead of step 0, so it numbers one behind it.
  static const int briefingPosition = -1;

  final List<SolutionTrailNode> nodes;

  /// Called with a node's [SolutionTrailNode.travelTo] when the student taps
  /// it. A null callback disables travel.
  final void Function(int position)? onNodeTap;

  const SolutionTrailMolecule({
    super.key,
    required this.nodes,
    this.onNodeTap,
  });

  @override
  State<SolutionTrailMolecule> createState() => _SolutionTrailMoleculeState();
}

class _SolutionTrailMoleculeState extends State<SolutionTrailMolecule> {
  final ScrollController _controller = ScrollController();

  /// Node-to-node distance inside the panning strip, settled by the last
  /// layout. [_centreCurrent] needs it and cannot ask the render tree, so
  /// layout hands it over.
  double _stride = SolutionTrailMolecule.stepNodeSize +
      SolutionTrailMolecule.minLinkWidth +
      SolutionTrailMolecule.linkMargin * 2;

  bool _moreLeft = false;
  bool _moreRight = false;

  /// Where the panning strip starts in [SolutionTrailMolecule.nodes] — 1 when
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
  void didUpdateWidget(SolutionTrailMolecule oldWidget) {
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

    const nodeSize = SolutionTrailMolecule.stepNodeSize;
    final centre =
        SolutionTrailMolecule.stripPad + index * _stride + nodeSize / 2;
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
          _TrailNode(
            index: 0,
            node: nodes.first,
            size: SolutionTrailMolecule.headNodeSize,
            onTap: _tapFor(0),
          ),
          const SizedBox(width: SolutionTrailMolecule.pinGap),
        ],
        Expanded(child: _panningStrip()),
        if (hasTail) ...[
          const SizedBox(width: SolutionTrailMolecule.pinGap),
          _TrailNode(
            index: nodes.length - 1,
            node: nodes.last,
            size: SolutionTrailMolecule.tailNodeSize,
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
        const nodeSize = SolutionTrailMolecule.stepNodeSize;
        const margin = SolutionTrailMolecule.linkMargin;
        const minLink = SolutionTrailMolecule.minLinkWidth;

        // Links take the slack when there is any, and hold their minimum when
        // there is not — which is the point at which the strip starts panning.
        final gaps = steps.length - 1;
        final slack = constraints.maxWidth -
            SolutionTrailMolecule.stripPad * 2 -
            steps.length * nodeSize -
            gaps * margin * 2;
        final linkWidth =
            gaps > 0 && slack / gaps > minLink ? slack / gaps : minLink;
        _stride = nodeSize + linkWidth + margin * 2;

        const room = SolutionTrailMolecule.glowRoom;
        final barHeight = nodeSize + 14.h;

        return SizedBox(
          height: barHeight,
          child: OverflowBox(
            minHeight: barHeight + room * 2,
            maxHeight: barHeight + room * 2,
            child: _EdgeFade(
              left: _moreLeft,
              right: _moreRight,
              child: SingleChildScrollView(
                key: const Key('solution_trail_scroll'),
                controller: _controller,
                scrollDirection: Axis.horizontal,
                // The current node is scaled up and glows past its own box; without
                // the padding the clip cuts the glow off mid-halo.
                padding: const EdgeInsets.symmetric(
                  horizontal: SolutionTrailMolecule.stripPad,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < steps.length; i++) ...[
                      _TrailNode(
                        index: offset + i,
                        node: steps[i],
                        size: nodeSize,
                        onTap: _tapFor(offset + i),
                      ),
                      if (i < steps.length - 1)
                        _TrailConnector(
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

class _TrailNode extends StatelessWidget {
  final int index;
  final SolutionTrailNode node;
  final double size;
  final VoidCallback? onTap;

  const _TrailNode({
    required this.index,
    required this.node,
    required this.size,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = node.state == SolutionTrailNodeState.current;
    final isMarker = node.shape == SolutionTrailNodeShape.marker;

    final Color foreground;
    Color? fill;
    Gradient? gradient;
    Border border;
    List<BoxShadow> shadows = const [];

    if (isMarker) {
      // Bookends are outlined, never filled. A solid mint marker is the same
      // paint as a banked step, and the plan is not a step the student earned
      // -- it is a place they can go back to.
      final line = switch (node.state) {
        SolutionTrailNodeState.done => QuestPalette.mint,
        SolutionTrailNodeState.ready => QuestPalette.amber,
        _ => QuestPalette.markerLine,
      };
      foreground = line;
      fill = line.withValues(alpha: 0.16);
      border = Border.all(color: line, width: 2);
      if (node.state == SolutionTrailNodeState.ready) {
        shadows = [
          BoxShadow(
            color: QuestPalette.amber.withValues(alpha: 0.35),
            blurRadius: 13,
          ),
        ];
      }
    } else {
      switch (node.state) {
        case SolutionTrailNodeState.done:
          fill = QuestPalette.mint;
          foreground = QuestPalette.onMint;
          border = Border.all(color: QuestPalette.mint, width: 2);
        case SolutionTrailNodeState.current:
          gradient = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [QuestPalette.pink, QuestPalette.violet],
          );
          foreground = Colors.white;
          border = Border.all(color: Colors.white, width: 2);
          shadows = [
            BoxShadow(
              color: QuestPalette.pink.withValues(alpha: 0.45),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ];
        case SolutionTrailNodeState.ready:
          fill = QuestPalette.amber;
          foreground = QuestPalette.onAmber;
          border = Border.all(color: QuestPalette.amber, width: 2);
          shadows = [
            BoxShadow(
              color: QuestPalette.amber.withValues(alpha: 0.4),
              blurRadius: 13,
            ),
          ];
        case SolutionTrailNodeState.upcoming:
          fill = Colors.white.withValues(alpha: 0.05);
          foreground = QuestPalette.dim.withValues(alpha: 0.75);
          border = Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          );
      }
    }

    // The current node is the only one that grows. Scaling rather than sizing
    // keeps every node on one baseline, so the trail does not jog as you move.
    final scale = isCurrent ? 1.14 : 1.0;

    Widget dot = Container(
      key: Key('trail_node_$index'),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        gradient: gradient,
        shape: isMarker ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isMarker ? BorderRadius.circular(size * 0.32) : null,
        border: border,
        boxShadow: shadows,
      ),
      child: _content(foreground),
    );

    if (node.invites) {
      dot = _InviteRing(size: size, marker: isMarker, child: dot);
    }

    final chainsBroken = node.chainsBroken;
    if (chainsBroken != null) {
      dot = _VaultChains(size: size, broken: chainsBroken, child: dot);
    }

    if (isCurrent) {
      dot = _CurrentNodeHalo(size: size, marker: isMarker, child: dot);
    }

    if (onTap != null) {
      dot = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          key: Key('trail_node_tap_$index'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: dot,
        ),
      );
    }

    return Semantics(
      label: node.semanticsLabel,
      button: onTap != null,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Transform.scale(scale: scale, child: dot),
        ),
      ),
    );
  }

  /// A done step always reads as a tick. A done *marker* keeps its own icon —
  /// the vault reads as an open vault, not as a generic tick.
  Widget _content(Color foreground) {
    final icon = node.icon;
    if (node.state == SolutionTrailNodeState.done && icon == null) {
      return Icon(Icons.check_rounded, size: 15.sp, color: foreground);
    }
    if (icon != null) {
      return Icon(icon, size: 15.sp, color: foreground);
    }
    return Text(
      '${node.displayNumber}',
      style: TextStyle(
        fontFamily: kDisplayFont,
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
    );
  }
}

/// A ring that breathes outward a few times, saying the node underneath can be
/// gone back to.
class _InviteRing extends StatelessWidget {
  final double size;
  final bool marker;
  final Widget child;

  const _InviteRing({
    required this.size,
    required this.marker,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return IdleBeatAtom(
      period: const Duration(milliseconds: 3400),
      beats: 3,
      child: child,
      builder: (context, phase, child) {
        // Out and gone, then back to the start: the ring leaves rather than
        // fading where it stands.
        final out = (1 - math.cos(phase * 2 * math.pi)) / 2;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            child!,
            if (out > 0)
              Positioned(
                left: -6,
                right: -6,
                top: -6,
                bottom: -6,
                child: IgnorePointer(
                  child: Transform.scale(
                    scale: 1 + 0.16 * out,
                    child: DecoratedBox(
                      key: const Key('trail_invite_ring'),
                      decoration: BoxDecoration(
                        shape: marker ? BoxShape.rectangle : BoxShape.circle,
                        borderRadius:
                            marker ? BorderRadius.circular(size * 0.42) : null,
                        border: Border.all(
                          color: QuestPalette.violet
                              .withValues(alpha: 0.5 * (1 - out)),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Three short bars strapped across the vault marker.
///
/// They break one at a time as the working is done, so the student can see the
/// answer coming loose. A chain does not fade when it goes — it snaps and is
/// flung off, because it was broken rather than switched off.
/// One drawn piece of a vault strap, in 38px node units measured from the
/// node centre.
typedef VaultBandSegment = ({Offset start, Offset end, double opacity});

/// Geometry of the straps that lash the vault shut.
///
/// [phase] runs 0 (intact) to 1 (snapped and gone). Pure, so the shape of the
/// thing can be argued with in a test rather than squinted at on a screen.
///
/// Two decisions live here. The straps reach past the node's 19-unit
/// half-width, because a band that stops at the silhouette reads as painted on
/// rather than wrapped around behind. And the last strap is drawn as two stubs
/// with a hole where the glyph sits, so it passes behind the lock instead of
/// striking it out - a bar through the middle of a lock reads as "wrong", which
/// is the last thing a page about getting the answer right should say.
List<VaultBandSegment> vaultBandSegments({
  required int index,
  required double phase,
}) {
  final band = _vaultBands[index];
  final strain = (phase / 0.28).clamp(0.0, 1.0);
  final snap =
      Curves.easeOutCubic.transform(((phase - 0.28) / 0.72).clamp(0.0, 1.0));
  final reach = _vaultReach * (1 + 0.09 * strain);
  final opacity = math.pow(1 - snap, 1.3).toDouble() * 0.74;

  if (opacity <= 0) return const [];

  // Straining, not yet broken: still one piece, drawn taut. Splitting it early
  // would show the two round caps meeting as a bulge at the centre.
  if (snap == 0) {
    if (band.gap == 0) {
      return [
        (
          start: Offset(-reach, band.y),
          end: Offset(reach, band.y),
          opacity: opacity,
        ),
      ];
    }
    return [
      (
        start: Offset(-reach, band.y),
        end: Offset(-band.gap, band.y),
        opacity: opacity,
      ),
      (
        start: Offset(band.gap, band.y),
        end: Offset(reach, band.y),
        opacity: opacity,
      ),
    ];
  }

  // Each half pivots about its outer end, so the free inner end is what falls -
  // the way a strained band gives way in the middle and the ends drop.
  final swing = 62 * snap * math.pi / 180;
  final drop = 7 * snap * snap;
  final apart = 1.5 * snap;

  VaultBandSegment half(double outerX, double innerX, double angle, double dx) {
    final anchor = Offset(outerX + dx, band.y + drop);
    final arm = innerX - outerX;
    return (
      start: anchor,
      end: anchor + Offset(arm * math.cos(angle), arm * math.sin(angle)),
      opacity: opacity,
    );
  }

  return [
    half(-reach, -band.gap, swing, -apart),
    half(reach, band.gap, -swing, apart),
  ];
}

/// Half-length of a strap. The node's half-width is 19, so every strap runs
/// past the silhouette on both sides.
const double _vaultReach = 21;
const double _vaultThickness = 2.6;

/// In break order: the outer straps go first and the one wrapped behind the
/// lock is the last to give, so the final chain standing still reads as a
/// chain rather than as an underline.
const List<({double y, double gap})> _vaultBands = [
  (y: -12.5, gap: 0),
  (y: 12.5, gap: 0),
  (y: 0, gap: 8.5),
];

class _VaultChains extends StatefulWidget {
  final double size;
  final int broken;
  final Widget child;

  const _VaultChains({
    required this.size,
    required this.broken,
    required this.child,
  });

  @override
  State<_VaultChains> createState() => _VaultChainsState();
}

class _VaultChainsState extends State<_VaultChains>
    with SingleTickerProviderStateMixin {
  late final AnimationController _snap;

  /// Chains already gone when this trail was drawn. Arriving at a part-solved
  /// question should not replay the breaking of chains broken long ago.
  late int _gone = widget.broken;
  Set<int> _snapping = const {};

  @override
  void initState() {
    super.initState();
    _snap = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
  }

  @override
  void didUpdateWidget(_VaultChains oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.broken == oldWidget.broken) return;
    if (widget.broken < _gone) {
      // Travelling back puts the chains on again; there is nothing to watch.
      _snap.stop();
      setState(() {
        _gone = widget.broken;
        _snapping = const {};
      });
      return;
    }
    if (!MotionPolicy.of(context)) {
      setState(() => _gone = widget.broken);
      return;
    }
    final target = widget.broken;
    setState(() {
      _snapping = {for (var i = _gone; i < target; i++) i};
    });
    _snap.forward(from: 0).whenCompleteOrCancel(() {
      if (!mounted || widget.broken != target) return;
      setState(() {
        _gone = target;
        _snapping = const {};
      });
    });
  }

  @override
  void dispose() {
    _snap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone >= _vaultBands.length && _snapping.isEmpty) return widget.child;
    final unit = widget.size / 38;
    return AnimatedBuilder(
      animation: _snap,
      builder: (context, child) {
        final t = _snap.value;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            child!,
            for (var i = 0; i < _vaultBands.length; i++)
              if (_snapping.contains(i))
                _band(i, t, unit)
              else if (i >= _gone)
                _band(i, 0, unit),
          ],
        );
      },
      child: widget.child,
    );
  }

  Widget _band(int index, double phase, double unit) {
    return CustomPaint(
      key: Key('vault_band_$index'),
      size: Size(widget.size, widget.size),
      painter: _VaultBandPainter(index: index, phase: phase, unit: unit),
    );
  }
}

/// Paints one strap. A painter rather than boxes because a strap has to spill
/// past the node it wraps, and nothing here clips.
class _VaultBandPainter extends CustomPainter {
  final int index;
  final double phase;
  final double unit;

  const _VaultBandPainter({
    required this.index,
    required this.phase,
    required this.unit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    for (final segment in vaultBandSegments(index: index, phase: phase)) {
      _draw(canvas, segment);
    }
    canvas.restore();
  }

  void _draw(Canvas canvas, VaultBandSegment segment) {
    final a = segment.start * unit;
    final b = segment.end * unit;
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = QuestPalette.dim.withValues(alpha: segment.opacity)
        ..strokeWidth = _vaultThickness * unit
        ..strokeCap = StrokeCap.round,
    );

    // A hairline of light along the top edge. Without it the strap is a flat
    // pill; with it, it is a band of metal.
    final run = segment.end - segment.start;
    final length = run.distance;
    if (length <= 3) return;
    final trim = run / length * 1.2;
    const lift = Offset(0, -_vaultThickness * 0.34);
    canvas.drawLine(
      (segment.start + trim + lift) * unit,
      (segment.end - trim + lift) * unit,
      Paint()
        ..color =
            const Color(0xFFFFFFFF).withValues(alpha: segment.opacity * 0.26)
        ..strokeWidth = 0.8 * unit
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_VaultBandPainter old) =>
      old.phase != phase || old.unit != unit || old.index != index;
}

class _TrailConnector extends StatelessWidget {
  final int index;
  final double width;
  final double margin;
  final bool lit;

  const _TrailConnector({
    required this.index,
    required this.width,
    required this.margin,
    required this.lit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin),
      width: width,
      height: 3,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
          // The lit run wipes outward from the node behind it, so a link reads
          // as ground being covered rather than a light switching on.
          Positioned.fill(
            // A fraction of the box, not an alignment of it: Positioned.fill
            // hands down tight constraints, and under those a widthFactor is
            // powerless -- the fill sizes to nothing and no link ever lights.
            child: AnimatedFractionallySizedBox(
              alignment: Alignment.centerLeft,
              duration: MotionPolicy.duration(
                context,
                const Duration(milliseconds: 450),
              ),
              curve: Curves.easeOut,
              widthFactor: lit ? 1.0 : 0.0,
              child: DecoratedBox(
                key: Key('trail_link_fill_$index'),
                decoration: BoxDecoration(
                  color: QuestPalette.mint,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The two things that mark where the student is standing.
///
/// A ring fires once the moment a node becomes current — that is the signal
/// that the page moved. As it dies a halo takes over and beats, which is what
/// makes the node findable at a glance in a trail too long to see at once.
///
/// **Divergence from the design, deliberate:** the prototype beats forever.
/// CSS lets the compositor handle that; a Flutter controller repainting a
/// shadow at 60fps forever never lets the frame loop idle, on a page a student
/// may leave open for the length of a problem. So the halo beats [_beats]
/// times and then rests. Nothing is lost — the node is already pink, filled,
/// enlarged and glowing at rest; the beat is emphasis, not the marker.
class _CurrentNodeHalo extends StatefulWidget {
  final double size;
  final bool marker;
  final Widget child;

  const _CurrentNodeHalo({
    required this.size,
    required this.marker,
    required this.child,
  });

  @override
  State<_CurrentNodeHalo> createState() => _CurrentNodeHaloState();
}

class _CurrentNodeHaloState extends State<_CurrentNodeHalo>
    with TickerProviderStateMixin {
  static const int _beats = 6;
  static const Duration _beatPeriod = Duration(milliseconds: 1700);

  late final AnimationController _ring;
  late final AnimationController _beat;

  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Built even when motion is off, so dispose never has to reach back into a
    // deactivated element to create the ticker it is about to throw away.
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _beat = AnimationController(
      vsync: this,
      duration: _beatPeriod * _beats,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || !MotionPolicy.idle(context)) return;
    _started = true;
    // The beat picks up exactly as the ring dies, which is the delay the
    // design gives it.
    _ring.forward().then((_) {
      if (mounted) _beat.forward();
    });
  }

  @override
  void dispose() {
    _ring.dispose();
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!MotionPolicy.idle(context)) return widget.child;

    final radius = widget.marker
        ? BorderRadius.circular(widget.size * 0.32)
        : BorderRadius.circular(widget.size);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _beat,
              builder: (context, _) {
                // A whole number of cycles, so the halo lands back on its
                // resting glow rather than stopping mid-pulse.
                final t =
                    (1 - math.cos(2 * math.pi * _beats * _beat.value)) / 2;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    boxShadow: [
                      BoxShadow(
                        color:
                            QuestPalette.pink.withValues(alpha: 0.30 * (1 - t)),
                        spreadRadius: 3 + 7 * t,
                      ),
                      BoxShadow(
                        color: QuestPalette.pink
                            .withValues(alpha: 0.55 + 0.25 * t),
                        blurRadius: 20 + 12 * t,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _ring,
              builder: (context, _) {
                if (_ring.isCompleted) return const SizedBox.shrink();
                final t = const Cubic(.18, .72, .28, 1).transform(_ring.value);
                return Transform.scale(
                  scale: 1 + 1.8 * t,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(
                        color:
                            QuestPalette.pink.withValues(alpha: 0.95 * (1 - t)),
                        width: 3 - 2 * t,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

/// Softens whichever end of the trail has more beyond it.
///
/// A trail that runs off the screen should look cut off, not finished — a hard
/// edge reads as "that is all the steps there are". The gradient is horizontal
/// only, so the current node's vertical glow passes through untouched.
class _EdgeFade extends StatelessWidget {
  static const double _fade = 26;

  final bool left;
  final bool right;
  final Widget child;

  const _EdgeFade({
    required this.left,
    required this.right,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!left && !right) return child;

    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final leftStop = left ? _fade / bounds.width : 0.0;
        final rightStop = right ? 1 - _fade / bounds.width : 1.0;
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [0, leftStop, rightStop, 1],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
