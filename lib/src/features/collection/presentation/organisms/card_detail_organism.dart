import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entity/card_rarity.dart';
import '../atoms/collectible_card_atom.dart';
import '../params/card_detail_params.dart';

/// One card, with its facts and the option to trade a copy.
///
/// **Capped at [maxWidth].** A Flutter `Dialog` expands to its child, so without
/// an explicit constraint the card drifts away from its facts on a wide window.
class CardDetailOrganism extends StatelessWidget {
  static const double maxWidth = 520;

  final CardDetailParams params;

  const CardDetailOrganism({super.key, required this.params});

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

    // Trading the only copy would empty the grid slot the student just filled,
    // so it is refused rather than offered and then undone.
    final canTrade = holding.standardCopies > 1;
    final payout = card.rarity.conversionValue;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: Container(
          key: const Key('card-detail-body'),
          padding: EdgeInsets.all(18.w),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CollectibleCardAtom(card: card, width: 132),
                  SizedBox(width: 18.w),
                  Expanded(
                    child: Column(
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
                        _Fact(label: 'Held', value: '${holding.totalCopies}'),
                        _Fact(
                            label: 'Rarity', value: _rarityLabel(card.rarity)),
                        _Fact(label: 'Deck', value: card.scaleLabel),
                        SizedBox(height: 16.h),
                        Center(
                          child: AppButtonAtom(
                            label: 'Trade one',
                            variant: AppButtonVariant.accent,
                            onPressed: canTrade
                                ? () => params.onConvert(CardVariant.standard)
                                : null,
                          ),
                        ),
                        if (canTrade)
                          Padding(
                            padding: EdgeInsets.only(top: 6.h),
                            child: Center(
                              child: Text(
                                '+$payout points',
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  color: QuestPalette.mint,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
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
          Text(label,
              style: TextStyle(fontSize: 11.sp, color: QuestPalette.dim)),
          Text(value,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: QuestPalette.cream,
              )),
        ],
      ),
    );
  }
}
