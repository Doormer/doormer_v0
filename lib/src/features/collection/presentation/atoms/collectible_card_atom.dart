import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entity/card_rarity.dart';
import '../../domain/entity/collectible_card.dart';

/// A card: full-bleed art with the name set over a scrim, and no frame.
///
/// Rarity is a brass halo whose weight grows with scarcity. **Common has none**,
/// which is what keeps the halo meaningful — if every card glowed, none would.
///
/// The scrim only reads because every card image is dark at its lower edge.
/// That is a constraint on the art brief, not something this widget guarantees.
class CollectibleCardAtom extends StatelessWidget {
  static const double aspectRatio = 2 / 3;

  final CollectibleCard card;
  final double width;
  final bool showScale;

  /// Copies held. One, or zero, shows no badge — the badge is for *more than
  /// one*, and a badge reading ×1 would be noise on every card.
  final int copies;

  /// Whether a special printing is held.
  ///
  /// Without this a special copy is indistinguishable from a plain one the
  /// moment the reveal is dismissed, so "Now special" would announce something
  /// the collection then never shows again.
  final bool isSpecial;

  const CollectibleCardAtom({
    super.key,
    required this.card,
    required this.width,
    this.showScale = true,
    this.copies = 1,
    this.isSpecial = false,
  });

  /// The halo for a rarity, or null when it should not glow at all.
  ///
  /// Sized as a fraction of the card, not in fixed pixels: a glow that keeps its
  /// radius while the card scales is too heavy on a grid tile and too faint on
  /// a reveal. Taking [width] rather than reading `ScreenUtil` keeps this
  /// callable from a test without pumping a widget first.
  static BoxShadow? haloFor(Rarity rarity, {required double width}) {
    switch (rarity) {
      case Rarity.common:
        return null;
      case Rarity.uncommon:
        return BoxShadow(
          color: QuestPalette.amber.withValues(alpha: 0.45),
          blurRadius: width * 0.096,
          spreadRadius: width * 0.005,
        );
      case Rarity.rare:
        return BoxShadow(
          color: QuestPalette.amber.withValues(alpha: 0.55),
          blurRadius: width * 0.212,
          spreadRadius: width * 0.029,
        );
    }
  }

  /// The colour a rarity flashes in: lavender for a common, brass for an
  /// uncommon or a rare. The draw's reveal and the shatter both use it. Brass
  /// is the rarity colour everywhere else, so a common must not borrow it.
  static Color rarityColour(Rarity rarity) =>
      rarity == Rarity.common ? QuestPalette.dim : QuestPalette.amber;

  @override
  Widget build(BuildContext context) {
    final w = width.w;
    final halo = haloFor(card.rarity, width: w);
    final radius = BorderRadius.circular(10.r);

    return Container(
      width: w,
      height: w / aspectRatio,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: w * 0.173,
            offset: Offset(0, w * 0.077),
          ),
          if (halo != null) halo,
        ],
        border: card.rarity == Rarity.common
            ? null
            : Border.all(
                color: QuestPalette.amber
                    .withValues(alpha: card.rarity == Rarity.rare ? 0.9 : 0.45),
                width: card.rarity == Rarity.rare ? 2.w : 1.5.w,
              ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // A dim panel under the art. It shows while the image loads, and
            // stays if the image fails, so the name and rarity still read.
            const ColoredBox(
              key: Key('card-art-panel'),
              color: QuestPalette.ink,
            ),
            Image.network(
              card.artUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.42, 0.74, 1.0],
                  colors: [
                    Color(0x000A0C14),
                    Color(0xDB0A0C14),
                    Color(0xFF070911),
                  ],
                ),
              ),
            ),
            // The special printing: a static diagonal mirror polish, sitting
            // above the art and below the name. The card brief calls it
            // "mirror polish"; it is deliberately still, unlike the sweep that
            // crosses the card once during a rare reveal.
            if (isSpecial)
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1.0, -0.6),
                        end: Alignment(1.0, 0.6),
                        stops: [0.30, 0.44, 0.50, 0.56, 0.70],
                        colors: [
                          Color(0x00FFFFFF),
                          Color(0x80FFFFFF),
                          Color(0xBFFFF4D6),
                          Color(0x73FFFFFF),
                          Color(0x00FFFFFF),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (copies > 1)
              Positioned(
                top: 6.h,
                right: 6.w,
                child: Container(
                  key: const Key('card-copies-badge'),
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: QuestPalette.night.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(999.r),
                    border: Border.all(
                      color: QuestPalette.cream.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Text(
                    '×$copies',
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: QuestPalette.cream,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(8.w, 7.h, 8.w, 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      card.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: (width * 0.088).sp,
                        height: 1.08,
                        fontWeight: FontWeight.w700,
                        color: QuestPalette.cream,
                      ),
                    ),
                    if (showScale)
                      Text(
                        card.scaleLabel.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: (width * 0.053).sp,
                          letterSpacing: 1.2,
                          color: QuestPalette.amber,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
