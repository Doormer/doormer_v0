import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum SolutionTrailNodeState { done, current, upcoming }

class SolutionTrailNode {
  final int displayNumber;
  final SolutionTrailNodeState state;
  final String semanticsLabel;

  const SolutionTrailNode({
    required this.displayNumber,
    required this.state,
    required this.semanticsLabel,
  });
}

/// The node trail — the page's only progress indicator.
///
/// Nodes shrink to fit but never below [minNodeSize]. Without that floor they
/// collapse to exactly 0px at nine steps and the trail silently stops
/// existing, so the row scrolls horizontally instead of squeezing.
class SolutionTrailMolecule extends StatelessWidget {
  static const double minNodeSize = 34;

  final List<SolutionTrailNode> nodes;

  const SolutionTrailMolecule({super.key, required this.nodes});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const connectorWidth = 18.0;
        final available = constraints.maxWidth;
        final connectors = (nodes.length - 1).clamp(0, nodes.length);
        final perNode = nodes.isEmpty
            ? minNodeSize
            : (available - connectors * connectorWidth) / nodes.length;
        final nodeSize = perNode < minNodeSize ? minNodeSize : perNode;
        final capped = nodeSize > 44.0 ? 44.0 : nodeSize;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
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
    final cs = context.colorScheme;

    final Color background;
    final Color foreground;
    final Color border;
    switch (node.state) {
      case SolutionTrailNodeState.done:
        background = cs.primaryContainer;
        foreground = cs.onPrimaryContainer;
        border = cs.primary;
      case SolutionTrailNodeState.current:
        background = cs.primary;
        foreground = cs.onPrimary;
        border = cs.primary;
      case SolutionTrailNodeState.upcoming:
        background = cs.surfaceContainerHighest;
        foreground = cs.onSurfaceVariant;
        border = cs.outlineVariant;
    }

    return Semantics(
      label: node.semanticsLabel,
      child: Container(
        key: Key('trail_node_$index'),
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(color: border, width: 2),
        ),
        child: node.state == SolutionTrailNodeState.done
            ? Icon(Icons.check, size: 16.sp, color: foreground)
            : Text(
                '${node.displayNumber}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
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
    final cs = context.colorScheme;
    return Container(
      width: width,
      height: 3,
      color: lit ? cs.primary : cs.outlineVariant,
    );
  }
}
