import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/card_picture_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../params/picture_picker_params.dart';

/// Picks the picture friends see: the nickname's first letter, or one of the
/// student's cards, in a grid. A student with no cards yet is told the
/// letter shows until they have one, and can carry on.
class PicturePickerOrganism extends StatelessWidget {
  final PicturePickerParams params;

  const PicturePickerOrganism({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Picture',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: QuestPalette.dim,
          ),
        ),
        SizedBox(height: 8.h),
        if (params.cards.isEmpty) ...[
          Text(
            'Your first letter shows until you have a card. '
            'Draw one on Cards.',
            style: TextStyle(fontSize: 12.sp, color: QuestPalette.muted),
          ),
          SizedBox(height: 8.h),
        ],
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: [
            _Choice(
              label: 'First letter',
              isChosen: params.isFirstLetterChosen,
              onTap: params.onChooseFirstLetter,
              child: CardPictureAtom(
                name: params.nickname,
                artUrl: null,
                size: 56.w,
              ),
            ),
            for (final card in params.cards)
              _Choice(
                label: card.name,
                isChosen: card.isChosen,
                onTap: card.onChoose,
                child: CardPictureAtom(
                  name: card.name,
                  artUrl: card.artUrl,
                  size: 56.w,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A tile to pick, ringed when it is the one picked. Screen readers hear a
/// radio button, checked when picked: the web reads `checked`, but has no
/// mapping for `selected`.
class _Choice extends StatelessWidget {
  final String label;
  final bool isChosen;
  final VoidCallback onTap;
  final Widget child;

  const _Choice({
    required this.label,
    required this.isChosen,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: isChosen,
      inMutuallyExclusiveGroup: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isChosen ? QuestPalette.amber : Colors.transparent,
              width: 2.w,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
