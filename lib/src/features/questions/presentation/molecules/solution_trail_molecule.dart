import 'dart:math' as math;
import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
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

  const SolutionTrailNode({
    required this.displayNumber,
    required this.state,
    required this.semanticsLabel,
    this.icon,
    this.shape = SolutionTrailNodeShape.step,
    this.travelTo,
  });
}

/// The node trail — the page's only progress indicator.
///
/// Nodes shrink to fit but never below [minNodeSize]. Without that floor they
/// collapse to exactly 0px at nine steps and the trail silently stops
/// existing, so the row scrolls horizontally instead of squeezing.
///
/// Colour is the whole language: mint is banked, pink is here, dim is ahead,
/// amber is openable. A link lights mint only once the node behind it is done,
/// so the lit run always reads as ground already covered.
class SolutionTrailMolecule extends StatefulWidget {
  static const double minNodeSize = 34;
  static const double connectorWidth = 16;

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

  double _nodeSize = SolutionTrailMolecule.minNodeSize;
  bool _moreLeft = false;
  bool _moreRight = false;

  int get _currentIndex => widget.nodes
      .indexWhere((n) => n.state == SolutionTrailNodeState.current);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncEdges);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncEdges());
  }

  @override
  void didUpdateWidget(SolutionTrailMolecule oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.nodes
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

    final stride = _nodeSize + SolutionTrailMolecule.connectorWidth;
    final centre = index * stride + _nodeSize / 2;
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

    return LayoutBuilder(
      builder: (context, constraints) {
        const connectorWidth = SolutionTrailMolecule.connectorWidth;
        final available = constraints.maxWidth;
        final connectors = (nodes.length - 1).clamp(0, nodes.length);
        final perNode = nodes.isEmpty
            ? SolutionTrailMolecule.minNodeSize
            : (available - connectors * connectorWidth) / nodes.length;
        final nodeSize = perNode < SolutionTrailMolecule.minNodeSize
            ? SolutionTrailMolecule.minNodeSize
            : perNode;
        final capped = nodeSize > 40.0 ? 40.0 : nodeSize;
        _nodeSize = capped;

        return _EdgeFade(
          left: _moreLeft,
          right: _moreRight,
          child: SingleChildScrollView(
            key: const Key('solution_trail_scroll'),
            controller: _controller,
            scrollDirection: Axis.horizontal,
            // The current node is scaled up and glows past its own box; without
            // the padding the clip cuts the glow off mid-halo.
            padding: EdgeInsets.symmetric(vertical: 7.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < nodes.length; i++) ...[
                  _TrailNode(
                    index: i,
                    node: nodes[i],
                    size: capped,
                    onTap: _tapFor(i),
                  ),
                  if (i < nodes.length - 1)
                    _TrailConnector(
                      width: connectorWidth,
                      lit: nodes[i].state == SolutionTrailNodeState.done,
                    ),
                ],
              ],
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

class _TrailConnector extends StatelessWidget {
  final double width;
  final bool lit;

  const _TrailConnector({required this.width, required this.lit});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 3,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // The lit run wipes outward from the node behind it, so a link reads
          // as ground being covered rather than a light switching on.
          Positioned.fill(
            child: AnimatedAlign(
              alignment: Alignment.centerLeft,
              duration: MotionPolicy.duration(
                context,
                const Duration(milliseconds: 450),
              ),
              curve: Curves.easeOut,
              widthFactor: lit ? 1.0 : 0.0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: QuestPalette.mint,
                  borderRadius: BorderRadius.circular(2),
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
                final t = (1 - math.cos(2 * math.pi * _beats * _beat.value)) / 2;
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
                        color:
                            QuestPalette.pink.withValues(alpha: 0.55 + 0.25 * t),
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
