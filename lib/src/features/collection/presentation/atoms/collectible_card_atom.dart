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
/// The scrim only reads because every bundled image is dark at its lower edge.
/// That is a constraint on the art brief, not something this widget guarantees.
class CollectibleCardAtom extends StatelessWidget {
  static const double aspectRatio = 2 / 3;

  final CollectibleCard card;
  final double width;
  final bool showScale;

  /// Copies held. One, or zero, shows no badge — the badge is for *more than
  /// one*, and a badge reading ×1 would be noise on every card.
  final int copies;

  const CollectibleCardAtom({
    super.key,
    required this.card,
    required this.width,
    this.showScale = true,
    this.copies = 1,
  });

  /// The halo for a rarity, or null when it should not glow at all.
  static BoxShadow? haloFor(Rarity rarity) {
    switch (rarity) {
      case Rarity.common:
        return null;
      case Rarity.uncommon:
        return BoxShadow(
          color: QuestPalette.amber.withValues(alpha: 0.45),
          blurRadius: 10,
          spreadRadius: 0.5,
        );
      case Rarity.rare:
        return BoxShadow(
          color: QuestPalette.amber.withValues(alpha: 0.55),
          blurRadius: 22,
          spreadRadius: 3,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = width.w;
    final halo = haloFor(card.rarity);
    final radius = BorderRadius.circular(10.r);

    return Container(
      width: w,
      height: w / aspectRatio,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
            Image.asset(card.artAsset, fit: BoxFit.cover),
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
            if (copies > 1)
              Positioned(
                top: 6.h,
                right: 6.w,
                child: Container(
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
