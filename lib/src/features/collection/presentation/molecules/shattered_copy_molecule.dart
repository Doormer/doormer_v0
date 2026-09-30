import 'dart:math' as math;

import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entity/card_rarity.dart';
import '../../domain/entity/collectible_card.dart';
import '../atoms/collectible_card_atom.dart';

/// One piece of a shattered copy.
///
/// Its points are fractions of the card's width and height, from 0 to 1, so
/// the same shard fits a card of any size. The first point is where the copy
/// was struck.
class Shard {
  final List<Offset> points;

  const Shard(this.points);

  /// The middle of the shard. It flies away from where the copy was struck,
  /// and shrinks into a quark dot here.
  Offset get centre {
    var sum = Offset.zero;
    for (final point in points) {
      sum += point;
    }
    return sum / points.length.toDouble();
  }

  /// The shard's outline on a card of [size].
  Path outlineIn(Size size) => Path()
    ..addPolygon([
      for (final point in points)
        Offset(point.dx * size.width, point.dy * size.height),
    ], true);
}

/// A copy breaking into shards, which shrink into quark dots that fly into
/// the quark balance, drawn at one instant.
///
/// It has no controller or timer. The window runs [progress] from 0 to 1 over
/// [duration], and a test can show any instant. At 0 the shards sit exactly
/// on the card. From 0.9 on, nothing is drawn.
class ShatteredCopyMolecule extends StatelessWidget {
  static const Duration duration = Duration(milliseconds: 1000);

  /// How long one quark dot takes to reach the balance, as a share of the
  /// whole shatter.
  static const double _quarkDotFlight = 0.20;

  static const _corners = [
    Offset(0, 0),
    Offset(1, 0),
    Offset(1, 1),
    Offset(0, 1),
  ];

  final CollectibleCard card;

  /// Whether the shattered copy was the special printing. The shards show the
  /// copy that broke, not what is still held.
  final bool isSpecial;

  /// The card's width, in the design units [CollectibleCardAtom] takes.
  final double cardWidth;

  /// Where the card sits, in this molecule's coordinates.
  final Rect cardRect;

  /// Where the balance's quark dot sits, in this molecule's coordinates.
  final Offset quarkDotCentre;

  final List<Shard> shards;
  final int quarksGained;

  /// How far through the shatter this is, from 0 to 1.
  final double progress;

  const ShatteredCopyMolecule({
    super.key,
    required this.card,
    required this.isSpecial,
    required this.cardWidth,
    required this.cardRect,
    required this.quarkDotCentre,
    required this.shards,
    required this.quarksGained,
    required this.progress,
  });

  /// Cuts a copy into shards, a little differently for every [seed].
  ///
  /// Lines run from where the copy was struck, near its middle, out to the
  /// card's edge at evenly spaced angles, each nudged by the seed. Two
  /// neighbouring lines and the stretch of edge between them make one shard,
  /// so the shards cover the card exactly, with no gaps and no overlaps.
  static List<Shard> shardsFor(Rarity rarity, int seed) {
    final random = math.Random(seed);
    double nudge() => random.nextDouble() * 2 - 1;

    final count = switch (rarity) {
      Rarity.common => 6,
      Rarity.uncommon => 8,
      Rarity.rare => 11,
    };
    final struck = Offset(0.5 + 0.1 * nudge(), 0.45 + 0.1 * nudge());
    final step = 2 * math.pi / count;
    final turn = random.nextDouble() * step;
    final angles = [
      for (var i = 0; i < count; i++) turn + (i + 0.3 * nudge()) * step,
    ];

    return [
      for (var i = 0; i < count; i++)
        Shard([
          struck,
          _edgeAlong(struck, angles[i]),
          ..._cornersBetween(struck, angles[i], angles[(i + 1) % count]),
          _edgeAlong(struck, angles[(i + 1) % count]),
        ]),
    ];
  }

  /// Where a line from [from] at [angle] meets the card's edge.
  static Offset _edgeAlong(Offset from, double angle) {
    final dx = math.cos(angle);
    final dy = math.sin(angle);
    var reach = double.infinity;
    if (dx > 0) reach = math.min(reach, (1 - from.dx) / dx);
    if (dx < 0) reach = math.min(reach, -from.dx / dx);
    if (dy > 0) reach = math.min(reach, (1 - from.dy) / dy);
    if (dy < 0) reach = math.min(reach, -from.dy / dy);
    return Offset(
      (from.dx + dx * reach).clamp(0.0, 1.0),
      (from.dy + dy * reach).clamp(0.0, 1.0),
    );
  }

  /// The card's corners between the lines from [from] at [start] and [end],
  /// in the order the edge passes them.
  static List<Offset> _cornersBetween(Offset from, double start, double end) {
    double turnTo(Offset corner) =>
        (math.atan2(corner.dy - from.dy, corner.dx - from.dx) - start) %
        (2 * math.pi);
    final sweep = (end - start) % (2 * math.pi);
    return [
      for (final corner in _corners)
        if (turnTo(corner) > 0 && turnTo(corner) < sweep) corner,
    ]..sort((a, b) => turnTo(a).compareTo(turnTo(b)));
  }

  /// A seed for [shardsFor], from the card and how many copies are left, so
  /// each shatter of a card breaks differently. Worked out by hand rather
  /// than with `hashCode`, which differs between platforms.
  static int seedFor(String cardId, int copiesLeft) {
    var seed = copiesLeft;
    for (final unit in cardId.codeUnits) {
      seed = (seed * 31 + unit) & 0x3fffffff;
    }
    return seed;
  }

  /// How many of [dotCount] quark dots have reached the balance by
  /// [progress]. The window counts the balance up by this.
  static int quarkDotsLandedAt(double progress, int dotCount) {
    var landed = 0;
    for (var dot = 0; dot < dotCount; dot++) {
      if (progress >= _quarkDotLeaves(dot, dotCount) + _quarkDotFlight) {
        landed++;
      }
    }
    return landed;
  }

  /// When quark dot [dot] leaves for the balance. The first leaves at 0.55
  /// and the last at 0.70, so the last lands at 0.90.
  static double _quarkDotLeaves(int dot, int dotCount) =>
      dotCount == 1 ? 0.70 : 0.55 + 0.15 * dot / (dotCount - 1);

  /// Where [progress] is between [start] and [end], from 0 to 1.
  static double _between(double progress, double start, double end) =>
      ((progress - start) / (end - start)).clamp(0.0, 1.0);

  /// How far shard [i] has moved from its place on the card at [at]: up a
  /// little as the copy lifts, then out from where it was struck, falling.
  Offset _shardMoved(int i, double at) {
    final away = shards[i].centre - shards.first.points.first;
    final direction =
        away.distance < 1e-6 ? const Offset(0, -1) : away / away.distance;
    final lift = _between(at, 0, 0.10);
    final fly = _between(at, 0.10, 0.50);
    return Offset(0, -6.h * lift) +
        direction *
            (cardRect.width * 0.55 * Curves.easeOutCubic.transform(fly)) +
        Offset(0, cardRect.height * 0.15 * fly * fly);
  }

  /// Where the middle of shard [i] is at [at], in this molecule's coordinates.
  Offset _shardCentreAt(int i, double at) {
    final centre = shards[i].centre;
    return cardRect.topLeft +
        Offset(centre.dx * cardRect.width, centre.dy * cardRect.height) +
        _shardMoved(i, at);
  }

  bool _quarkDotShows(int i) =>
      progress > 0.45 &&
      progress < _quarkDotLeaves(i, shards.length) + _quarkDotFlight;

  bool get _quarksGainedShows => progress > 0.10 && progress < 0.70;

  @override
  Widget build(BuildContext context) {
    final colour = CollectibleCardAtom.rarityColour(card.rarity);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (progress < 0.65)
          for (var i = 0; i < shards.length; i++) _shard(i, colour),
        for (var i = 0; i < shards.length; i++)
          if (_quarkDotShows(i)) _quarkDot(i),
        if (_quarksGainedShows) _quarksGained(),
      ],
    );
  }

  /// Shard [i]: the card, cut to the shard's outline and edged in the
  /// rarity's colour. It flashes, flies out, spins, and shrinks away.
  Widget _shard(int i, Color colour) {
    final shard = shards[i];
    final centre = Offset(
      shard.centre.dx * cardRect.width,
      shard.centre.dy * cardRect.height,
    );
    final moved = _shardMoved(i, progress);
    final fly = Curves.easeOutCubic.transform(_between(progress, 0.10, 0.50));
    final spin = (i.isEven ? 1 : -1) * (0.6 + 0.15 * (i % 4)) * fly;
    final size = 1 - _between(progress, 0.40, 0.65);
    final flash = progress < 0.10
        ? 0.6 * _between(progress, 0, 0.10)
        : 0.6 * (1 - _between(progress, 0.10, 0.35));

    return Positioned.fromRect(
      rect: cardRect,
      child: Transform(
        transform: Matrix4.identity()
          ..translate(centre.dx + moved.dx, centre.dy + moved.dy)
          ..rotateZ(spin)
          ..scale(size, size)
          ..translate(-centre.dx, -centre.dy),
        child: Opacity(
          opacity: 1 - _between(progress, 0.45, 0.65),
          child: CustomPaint(
            foregroundPainter: _ShardEdgePainter(shard, colour),
            child: ClipPath(
              key: ValueKey('shard-$i'),
              clipper: _ShardClipper(shard),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CollectibleCardAtom(
                    card: card,
                    width: cardWidth,
                    isSpecial: isSpecial,
                  ),
                  if (flash > 0)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colour.withValues(alpha: flash),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Quark dot [i]: it grows where shard [i] came to rest, then flies into
  /// the balance, speeding up as it goes.
  Widget _quarkDot(int i) {
    final leaves = _quarkDotLeaves(i, shards.length);
    final flight = Curves.easeInCubic
        .transform(_between(progress, leaves, leaves + _quarkDotFlight));
    final at = Offset.lerp(_shardCentreAt(i, 1), quarkDotCentre, flight)!;
    final size = 6.w * _between(progress, 0.45, 0.65);

    return Positioned(
      left: at.dx - size / 2,
      top: at.dy - size / 2,
      child: Container(
        key: ValueKey('quark-dot-$i'),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: QuestPalette.amber,
          boxShadow: [
            BoxShadow(
              color: QuestPalette.amber.withValues(alpha: 0.7),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }

  /// "+5 quarks", rising from where the copy was struck, then fading.
  Widget _quarksGained() {
    final struck = shards.first.points.first;
    final from = cardRect.topLeft +
        Offset(struck.dx * cardRect.width, struck.dy * cardRect.height);
    final rise = Curves.easeOutCubic.transform(_between(progress, 0.10, 0.70));
    final opacity =
        _between(progress, 0.10, 0.20) * (1 - _between(progress, 0.50, 0.70));

    return Positioned(
      left: from.dx,
      top: from.dy - 44.h * rise,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Opacity(
          opacity: opacity,
          child: Text(
            '+$quarksGained quarks',
            style: TextStyle(
              fontFamily: kDisplayFont,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: QuestPalette.mint,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShardClipper extends CustomClipper<Path> {
  final Shard shard;

  const _ShardClipper(this.shard);

  @override
  Path getClip(Size size) => shard.outlineIn(size);

  @override
  bool shouldReclip(_ShardClipper oldClipper) => oldClipper.shard != shard;
}

class _ShardEdgePainter extends CustomPainter {
  final Shard shard;
  final Color colour;

  const _ShardEdgePainter(this.shard, this.colour);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      shard.outlineIn(size),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = colour.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(_ShardEdgePainter oldDelegate) =>
      oldDelegate.shard != shard || oldDelegate.colour != colour;
}
