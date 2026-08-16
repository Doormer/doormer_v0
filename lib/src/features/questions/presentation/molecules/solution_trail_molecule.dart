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

  const SolutionTrailNode({
    required this.displayNumber,
    required this.state,
    required this.semanticsLabel,
    this.icon,
    this.shape = SolutionTrailNodeShape.step,
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
class SolutionTrailMolecule extends StatelessWidget {
  static const double minNodeSize = 34;

  final List<SolutionTrailNode> nodes;

  const SolutionTrailMolecule({super.key, required this.nodes});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const connectorWidth = 16.0;
        final available = constraints.maxWidth;
        final connectors = (nodes.length - 1).clamp(0, nodes.length);
        final perNode = nodes.isEmpty
            ? minNodeSize
            : (available - connectors * connectorWidth) / nodes.length;
        final nodeSize = perNode < minNodeSize ? minNodeSize : perNode;
        final capped = nodeSize > 40.0 ? 40.0 : nodeSize;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // The current node is scaled up and glows past its own box; without
          // the padding the clip cuts the glow off mid-halo.
          padding: EdgeInsets.symmetric(vertical: 7.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < nodes.length; i++) ...[
                _TrailNode(index: i, node: nodes[i], size: capped),
                if (i < nodes.length - 1)
                  _TrailConnector(
                    width: connectorWidth,
                    lit: nodes[i].state == SolutionTrailNodeState.done,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TrailNode extends StatelessWidget {
  final int index;
  final SolutionTrailNode node;
  final double size;

  const _TrailNode({
    required this.index,
    required this.node,
    required this.size,
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

    return Semantics(
      label: node.semanticsLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Transform.scale(
            scale: scale,
            child: Container(
              key: Key('trail_node_$index'),
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                gradient: gradient,
                shape: isMarker ? BoxShape.rectangle : BoxShape.circle,
                borderRadius:
                    isMarker ? BorderRadius.circular(size * 0.32) : null,
                border: border,
                boxShadow: shadows,
              ),
              child: _content(foreground),
            ),
          ),
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
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: lit ? QuestPalette.mint : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
