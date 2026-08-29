import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/atoms/current_node_halo_atom.dart';
import 'package:doormer/src/features/questions/presentation/atoms/invite_ring_atom.dart';
import 'package:doormer/src/features/questions/presentation/atoms/vault_chains_atom.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_trail_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One node on the trail: the dot itself, plus whichever of the three
/// decorations its state has earned — the invite ring, the vault chains, and
/// the halo that marks where the student is standing.
class TrailNodeMolecule extends StatelessWidget {
  final int index;
  final SolutionTrailNode node;
  final double size;
  final VoidCallback? onTap;

  const TrailNodeMolecule({
    super.key,
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
    final chainsBroken = node.chainsBroken;
    final content = _content(foreground);

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
      // A chained node keeps its glyph outside the box, so the chain can be
      // laid between the two and pass behind the lock.
      child: chainsBroken == null ? content : null,
    );

    if (node.invites) {
      dot = InviteRingAtom(size: size, marker: isMarker, child: dot);
    }

    if (chainsBroken != null) {
      dot = VaultChainsAtom(
        size: size,
        broken: chainsBroken,
        lock: content,
        child: dot,
      );
    }

    if (isCurrent) {
      dot = CurrentNodeHaloAtom(size: size, marker: isMarker, child: dot);
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
