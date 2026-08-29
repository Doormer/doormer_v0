import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';

/// One drawn run of chain, in 38px node units measured from the node centre.
///
/// [start] and [end] are the outer ends of the *painted* chain, not the centres
/// of the end links, so a run can be checked against the node silhouette
/// without knowing how the links are spaced inside it.
typedef VaultChainSegment = ({Offset start, Offset end, double opacity});

/// Geometry of the chains that lash the vault shut.
///
/// [phase] runs 0 (intact) to 1 (snapped and gone). Pure, so the shape of the
/// thing can be argued with in a test rather than squinted at on a screen.
///
/// Every chain is one unbroken run. The chains reach past the node's 19-unit
/// half-width, because a chain that stops at the silhouette reads as painted on
/// rather than wrapped around behind - and the middle one runs straight across
/// the lock, because the lock is painted over the top of it. Cutting a hole in
/// the chain to clear the glyph is what a drawing does; a chain lying on a box
/// goes behind the fittings, and a chain with a gap already in it is a chain
/// somebody has already cut.
List<VaultChainSegment> vaultChainSegments({
  required int index,
  required double phase,
}) {
  final chain = _vaultChains[index];
  final strain = (phase / 0.28).clamp(0.0, 1.0);
  final snap =
      Curves.easeOutCubic.transform(((phase - 0.28) / 0.72).clamp(0.0, 1.0));
  final reach = chain.reach * (1 + 0.09 * strain);
  final opacity = math.pow(1 - snap, 1.3).toDouble() * 0.86;

  if (opacity <= 0) return const [];

  // Straining, not yet broken: still one length of chain, drawn taut.
  if (snap == 0) {
    return [
      (
        start: Offset(-reach, chain.y),
        end: Offset(reach, chain.y),
        opacity: opacity,
      ),
    ];
  }

  // Each half pivots about its outer end, so the free inner end is what falls -
  // the way a chain gives way in the middle and the loose ends drop.
  final swing = 62 * snap * math.pi / 180;
  final drop = 7 * snap * snap;
  final apart = 1.5 * snap;

  VaultChainSegment half(
      double outerX, double innerX, double angle, double dx) {
    final anchor = Offset(outerX + dx, chain.y + drop);
    final arm = innerX - outerX;
    return (
      start: anchor,
      end: anchor + Offset(arm * math.cos(angle), arm * math.sin(angle)),
      opacity: opacity,
    );
  }

  return [
    half(-reach, 0, swing, -apart),
    half(reach, 0, -swing, apart),
  ];
}

/// A single link, measured along the run.
const double _vaultLinkLength = 8.2;

/// How far apart link centres sit. Shorter than a link, so neighbours overlap
/// and interlock the way real chain does. Spaced any wider they come apart into
/// a row of separate beads.
const double _vaultLinkPitch = 5.1;

/// A link face-on, and the same link seen edge-on. It is this alternation, not
/// the hole in the middle, that carries the chain at 44px - the hole is barely
/// three pixels across, but the change of width every few pixels is unmistakable.
const double _vaultLinkFace = 5.6;
const double _vaultLinkEdge = 2.0;

/// Thickness of the wire the links are bent from.
const double _vaultWire = 1.4;

/// How tall link [index] stands in a run.
///
/// Links alternate face-on and edge-on. That turn every second link is what
/// carries the chain at 44px - the hole through a link is barely three pixels
/// across, but a width that changes every few pixels is unmistakable. Drawn all
/// the same width they read as beads on a string.
double vaultChainLinkHeight(int index) =>
    index.isEven ? _vaultLinkFace : _vaultLinkEdge;

/// How many links fill a run of [length] node units.
///
/// Pure, because the alternative is counting ovals in a screenshot. The end
/// links sit half a link inside each end of the run, so the count comes from
/// the span between their centres rather than from the run itself.
int vaultChainLinkCount(double length) {
  final span = length - _vaultLinkLength;
  if (span <= 0) return 1;
  return (span / _vaultLinkPitch).round() + 1;
}

/// Where each shade sits across the height of a link.
const List<double> _vaultShadeStops = [0, 0.26, 0.6, 1];

/// A link read top to bottom.
///
/// A single flat colour makes the chain look like a chain *drawn* on the vault.
/// Four shades running light to dark make every link look like bent wire lit
/// from above, which is the whole difference between a picture of a lock and a
/// thing that looks locked. Derived from [QuestPalette.dim] so the chain stays
/// inert trail furniture rather than becoming a new colour with a new meaning.
/// It sits mostly *below* dim: pewter reads as iron, while a chain pitched at
/// dim or brighter turns white and outshines the vault it is holding shut.
List<Color> vaultChainShades() => [
      Color.lerp(QuestPalette.dim, QuestPalette.cream, 0.26)!,
      Color.lerp(QuestPalette.dim, QuestPalette.card, 0.20)!,
      Color.lerp(QuestPalette.dim, QuestPalette.card, 0.58)!,
      Color.lerp(QuestPalette.dim, QuestPalette.card, 0.81)!,
    ];

/// In break order: the outer chains go first and the one across the lock is the
/// last to give, so the chain still standing at the end is the one that matters.
///
/// The middle chain reaches further than the other two because the vault is
/// widest at its waist - the outer chains cross the corner curve, where the box
/// has already begun to pull in. Equal reach would leave the middle one looking
/// short of the edge.
const List<({double y, double reach})> _vaultChains = [
  (y: -11.5, reach: 21),
  (y: 11.5, reach: 21),
  (y: 0, reach: 22),
];

class VaultChainsAtom extends StatefulWidget {
  final double size;
  final int broken;

  /// The vault's own lock, drawn last so the chain passes behind it.
  final Widget lock;
  final Widget child;

  const VaultChainsAtom({
    super.key,
    required this.size,
    required this.broken,
    required this.lock,
    required this.child,
  });

  @override
  State<VaultChainsAtom> createState() => _VaultChainsAtomState();
}

class _VaultChainsAtomState extends State<VaultChainsAtom>
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
  void didUpdateWidget(VaultChainsAtom oldWidget) {
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
    if (_gone >= _vaultChains.length && _snapping.isEmpty) {
      return _stack(widget.child, const []);
    }
    final unit = widget.size / 38;
    return AnimatedBuilder(
      animation: _snap,
      builder: (context, child) {
        final t = _snap.value;
        return _stack(child!, [
          for (var i = 0; i < _vaultChains.length; i++)
            if (_snapping.contains(i))
              _chain(i, t, unit)
            else if (i >= _gone)
              _chain(i, 0, unit),
        ]);
      },
      child: widget.child,
    );
  }

  /// The box, then the chain, then the lock.
  ///
  /// Order is the whole trick. Painted under the chain the lock is struck
  /// through by the very thing holding it, which reads as "wrong" - the last
  /// thing a page about getting the answer right should say. Painted over it,
  /// the chain simply runs behind the lock and stays one unbroken length.
  Widget _stack(Widget box, List<Widget> chains) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        box,
        ...chains,
        KeyedSubtree(key: const Key('vault_lock'), child: widget.lock),
      ],
    );
  }

  Widget _chain(int index, double phase, double unit) {
    return CustomPaint(
      key: Key('vault_chain_$index'),
      size: Size(widget.size, widget.size),
      painter: _VaultChainPainter(index: index, phase: phase, unit: unit),
    );
  }
}

/// Paints one chain. A painter rather than boxes because the chain has to spill
/// past the node it wraps, and nothing here clips.
class _VaultChainPainter extends CustomPainter {
  final int index;
  final double phase;
  final double unit;

  const _VaultChainPainter({
    required this.index,
    required this.phase,
    required this.unit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    for (final segment in vaultChainSegments(index: index, phase: phase)) {
      _draw(canvas, segment);
    }
    canvas.restore();
  }

  void _draw(Canvas canvas, VaultChainSegment segment) {
    final a = segment.start * unit;
    final b = segment.end * unit;
    final run = b - a;
    final length = run.distance;
    if (length <= 0.5) return;

    canvas.save();
    canvas.translate((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    canvas.rotate(run.direction);

    final link = _vaultLinkLength * unit;
    final wire = _vaultWire * unit;
    final count = vaultChainLinkCount(length / unit);
    // Link centres are inset half a link from each end, so the chain finishes
    // where the run finishes instead of dangling half a link out in the air.
    final span = math.max(0.0, length - link);
    final step = count > 1 ? span / (count - 1) : 0.0;

    final shades = [
      for (final shade in vaultChainShades())
        shade.withValues(alpha: shade.a * segment.opacity),
    ];

    Rect linkAt(int i) => Rect.fromCenter(
          center: Offset(-span / 2 + step * i, 0),
          width: link,
          height: vaultChainLinkHeight(i) * unit,
        );

    // Every shadow first, then every link. Links overlap, so drawing each
    // one's shadow immediately before its own body lays that shadow back over
    // the neighbour already painted, and the whole chain silts up muddy.
    //
    // The chain lies on the vault rather than in it, so it drops a little
    // shade. Without this the metal sits in the same plane as the box and the
    // whole node goes flat.
    final shadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = wire
      ..color = QuestPalette.night.withValues(alpha: segment.opacity * 0.55);
    for (var i = 0; i < count; i++) {
      canvas.drawOval(linkAt(i).shift(Offset(0, wire * 0.5)), shadow);
    }

    for (var i = 0; i < count; i++) {
      final oval = linkAt(i);
      canvas.drawOval(
        oval,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = wire
          ..shader = ui.Gradient.linear(
            Offset(0, -(oval.height + wire) / 2),
            Offset(0, (oval.height + wire) / 2),
            shades,
            _vaultShadeStops,
          ),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_VaultChainPainter old) =>
      old.phase != phase || old.unit != unit || old.index != index;
}
