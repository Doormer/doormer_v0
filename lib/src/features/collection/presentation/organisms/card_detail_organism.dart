import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entity/card_rarity.dart';
import '../../domain/entity/holding.dart';
import '../atoms/collectible_card_atom.dart';
import '../params/card_detail_params.dart';

/// One card, with its facts and the option to shatter a copy.
///
/// **Capped at [maxWidth].** A Flutter `Dialog` expands to its child, so without
/// an explicit constraint the card drifts away from its facts on a wide window.
class CardDetailOrganism extends StatelessWidget {
  static const double maxWidth = 520;

  /// Below this the card sits above its facts rather than beside them.
  static const double stackBelowWidth = 420;

  final CardDetailParams params;

  const CardDetailOrganism({super.key, required this.params});

  /// How many are held, and how many of those are special.
  ///
  /// Three cases, because "3 · 3 special" says the same number twice:
  ///
  ///   none special  ->  `3`
  ///   some special  ->  `3 · 1 special`
  ///   all special   ->  `3 special`
  ///
  /// The count is the printing-agnostic total; the special part only appears
  /// when there is something to distinguish, so "Now special" leaves a trace
  /// rather than being announced once and then lost.
  static String heldLabel(Holding holding) {
    final total = holding.totalCopies;
    if (!holding.hasSpecial) return '$total';
    if (holding.specialCopies == total) return '$total special';
    return '$total · ${holding.specialCopies} special';
  }

  String _rarityLabel(Rarity rarity) {
    switch (rarity) {
      case Rarity.common:
        return 'Common';
      case Rarity.uncommon:
        return 'Uncommon';
      case Rarity.rare:
        return 'Rare';
    }
  }

  @override
  Widget build(BuildContext context) {
    final holding = params.holding;
    final card = holding.card;

    // Never shatter the last copy: that would empty the grid slot the
    // student just filled. Any copy beyond the first is fair game, whichever
    // printing it is.
    final canShatter = holding.totalCopies > 1;

    final variant = holding.variantToShatter;
    final shatterQuarks = card.shatterQuarksFor(variant);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: Container(
          key: const Key('card-detail-body'),
          padding: EdgeInsets.all(18.w),
          // A surface of its own. Without this the detail had padding but no
          // background, so the grid behind it showed straight through and the
          // two sets of text overlapped.
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: QuestPalette.cream.withValues(alpha: 0.08),
              width: 1.w,
            ),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [QuestPalette.ink, QuestPalette.night],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  key: const Key('card-detail-close'),
                  onPressed: params.onClose,
                  icon: Icon(Icons.close, size: 18.w),
                  color: QuestPalette.muted,
                  tooltip: 'Close',
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  // A phone cannot hold the card beside its facts: inside a
                  // Dialog's insets there is roughly 94px left for a label and
                  // its value, which overflows. The spec calls for the card
                  // above its facts on a narrow screen, and this is where that
                  // lives.
                  final stacked = constraints.maxWidth < stackBelowWidth;
                  final facts = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        card.description,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          height: 1.45,
                          color: QuestPalette.cream.withValues(alpha: 0.72),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      _Fact(label: 'Held', value: heldLabel(holding)),
                      _Fact(label: 'Rarity', value: _rarityLabel(card.rarity)),
                      _Fact(label: 'Deck', value: card.scaleLabel),
                      SizedBox(height: 16.h),
                      Center(
                        child: AppButtonAtom(
                          label: 'Shatter one',
                          variant: AppButtonVariant.accent,
                          onPressed: canShatter
                              ? () => params.onShatter(variant)
                              : null,
                        ),
                      ),
                      if (canShatter)
                        Padding(
                          padding: EdgeInsets.only(top: 6.h),
                          child: Center(
                            child: Text(
                              '+$shatterQuarks quarks',
                              style: TextStyle(
                                fontSize: 10.5.sp,
                                color: QuestPalette.mint,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );

                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: CollectibleCardAtom(
                            card: card,
                            width: 158,
                            isSpecial: holding.hasSpecial,
                          ),
                        ),
                        SizedBox(height: 14.h),
                        facts,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CollectibleCardAtom(
                        card: card,
                        width: 132,
                        isSpecial: holding.hasSpecial,
                      ),
                      SizedBox(width: 18.w),
                      Expanded(child: facts),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;

  const _Fact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.sp, color: QuestPalette.dim),
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: QuestPalette.cream,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
