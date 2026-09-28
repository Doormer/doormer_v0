import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entity/card_rarity.dart';
import '../molecules/closed_deck_molecule.dart';
import '../params/empty_deck_params.dart';

/// What a deck holding nothing shows.
///
/// The grid rule is held cards only, so at zero held there is no grid to draw
/// and the screen must state something instead. A closed deck says *there are
/// cards in here* without listing them, which keeps the rule intact.
///
/// The mix describes the deck's **contents**, not the chance of drawing them.
/// It must never be presented as odds.
class EmptyDeckOrganism extends StatelessWidget {
  final EmptyDeckParams params;

  const EmptyDeckOrganism({super.key, required this.params});

  String _label(Rarity rarity) {
    switch (rarity) {
      case Rarity.common:
        return 'common';
      case Rarity.uncommon:
        return 'uncommon';
      case Rarity.rare:
        return 'rare';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rarest first: the rare chip is the pull.
    final ordered = [Rarity.rare, Rarity.uncommon, Rarity.common]
        .where((r) => (params.rarityMix[r] ?? 0) > 0)
        .toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const ClosedDeckMolecule(),
        SizedBox(height: 20.h),
        Text(
          'Nothing here yet',
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
            color: QuestPalette.cream,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          // Digits, never words: deck sizes are unbounded.
          '${params.deckSize} cards to find',
          style: TextStyle(fontSize: 12.sp, color: QuestPalette.muted),
        ),
        SizedBox(height: 11.h),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6.w,
          runSpacing: 6.h,
          children: [
            for (final rarity in ordered)
              _MixChip(
                label: '${params.rarityMix[rarity]} ${_label(rarity)}',
                highlight: rarity == Rarity.rare,
              ),
          ],
        ),
        SizedBox(height: 18.h),
        AppButtonAtom(
          // The price rides on the label. Disabling the button must not hide
          // what a draw costs — that is the whole reason it stays on screen
          // rather than disappearing when it cannot be afforded.
          label: 'Draw a card · ${params.drawCost}',
          expand: true,
          onPressed: params.canAfford ? params.onDraw : null,
        ),
        if (!params.canAfford) ...[
          SizedBox(height: 9.h),
          Text(
            '${params.quarksShort} more quarks to draw',
            style: TextStyle(fontSize: 11.sp, color: QuestPalette.amber),
          ),
        ],
      ],
    );
  }
}

class _MixChip extends StatelessWidget {
  final String label;
  final bool highlight;

  const _MixChip({required this.label, required this.highlight});

  @override
  Widget build(BuildContext context) {
    final colour = highlight ? QuestPalette.amber : QuestPalette.dim;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: QuestPalette.cream.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: colour.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9.5.sp, color: colour),
      ),
    );
  }
}
