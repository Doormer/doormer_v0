import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entity/collection.dart';
import '../../domain/entity/holding.dart';
import '../mapper/collection_presenter.dart';
import '../organisms/card_grid_organism.dart';
import '../organisms/deck_list_organism.dart';
import '../organisms/empty_deck_organism.dart';

/// The collection, at every width.
///
/// The deck list is the home on both platforms. On a wide window it becomes a
/// rail with the open deck beside it; below [railBreakpoint] the list and the
/// deck are two screens.
class CollectionTemplate extends StatelessWidget {
  /// Where the rail can afford 190px of navigation without squeezing the grid.
  ///
  /// **Measured against the content column, not the window.**
  /// `ResponsiveAppShell` rewrites `MediaQuery` so `sizeOf(context).width`
  /// reports `min(windowWidth, 760)`. A breakpoint above 760 can therefore
  /// never be met and the rail would never appear at any window size.
  ///
  /// At 700 the rail takes 190 and leaves roughly 520 for the grid, which
  /// holds three 104px cards with their spacing.
  static const double railBreakpoint = 700;

  static const double railWidth = 190;

  final Collection collection;
  final String? selectedDeckId;
  final void Function(String deckId) onSelectDeck;
  final VoidCallback onCloseDeck;
  final VoidCallback onDraw;
  final void Function(Holding holding) onCardTap;

  const CollectionTemplate({
    super.key,
    required this.collection,
    required this.selectedDeckId,
    required this.onSelectDeck,
    required this.onCloseDeck,
    required this.onDraw,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= railBreakpoint;

    return Scaffold(
      backgroundColor: QuestPalette.night,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: isWide ? _wide(context) : _narrow(context),
        ),
      ),
    );
  }

  Widget _deckList({required bool isRail}) {
    return DeckListOrganism(
      rows: CollectionPresenter.deckRows(
        collection: collection,
        selectedDeckId: selectedDeckId,
        isRail: isRail,
        onSelect: onSelectDeck,
      ),
    );
  }

  Widget _wide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: railWidth.w,
          child: SingleChildScrollView(child: _deckList(isRail: true)),
        ),
        SizedBox(width: 20.w),
        Expanded(
          child: selectedDeckId == null
              ? const SizedBox.shrink()
              : _deckBody(context),
        ),
      ],
    );
  }

  Widget _narrow(BuildContext context) {
    if (selectedDeckId == null) {
      return SingleChildScrollView(child: _deckList(isRail: false));
    }
    return _deckBody(context, showBack: true);
  }

  Widget _deckBody(BuildContext context, {bool showBack = false}) {
    final deckId = selectedDeckId!;
    final holdings = collection.holdingsForDeck(deckId);
    final deck = collection.decks.firstWhere((d) => d.id == deckId);

    if (holdings.isEmpty) {
      return Column(
        children: [
          if (showBack) _backRow(deck.name),
          Expanded(
            child: EmptyDeckOrganism(
              params: CollectionPresenter.emptyDeck(
                collection: collection,
                deckId: deckId,
                onDraw: onDraw,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBack) _backRow(deck.name),
        Text(
          '${collection.heldCountFor(deckId)} of ${deck.size} held',
          style: TextStyle(fontSize: 11.5.sp, color: QuestPalette.dim),
        ),
        SizedBox(height: 14.h),
        Expanded(
          child: SingleChildScrollView(
            child: CardGridOrganism(
              holdings: holdings,
              cardWidth: 104,
              onCardTap: onCardTap,
            ),
          ),
        ),
        SizedBox(height: 14.h),
        AppButtonAtom(
          label: 'Draw a card · ${collection.drawCost}',
          expand: true,
          onPressed: collection.canAffordDraw ? onDraw : null,
        ),
      ],
    );
  }

  Widget _backRow(String deckName) {
    return Padding(
      padding: EdgeInsets.only(bottom: 13.h),
      child: InkWell(
        onTap: onCloseDeck,
        child: Row(
          children: [
            Icon(Icons.arrow_back, size: 16.w, color: QuestPalette.markerLine),
            SizedBox(width: 7.w),
            Text('Decks',
                style: TextStyle(fontSize: 12.sp, color: QuestPalette.muted)),
            SizedBox(width: 7.w),
            Text('·',
                style: TextStyle(fontSize: 12.sp, color: QuestPalette.muted)),
            SizedBox(width: 7.w),
            Text(
              deckName,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: QuestPalette.cream,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
