import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entity/collection.dart';
import '../../domain/entity/deck_progress.dart';
import '../../domain/entity/holding.dart';
import '../mapper/collection_presenter.dart';
import '../molecules/error_with_retry_molecule.dart';
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

  final int quarkBalance;
  final List<DeckProgress> decks;
  final String? selectedDeckId;

  /// The open deck. Null while it loads, or after reading it failed.
  final Collection? collection;

  /// Why the open deck could not load.
  final String? deckErrorMessage;

  /// A draw is in flight. Both draw buttons show a spinner until the drawn
  /// card is ready.
  final bool isDrawing;

  final void Function(String deckId) onSelectDeck;
  final VoidCallback onCloseDeck;
  final VoidCallback onDraw;
  final void Function(Holding holding) onCardTap;

  const CollectionTemplate({
    super.key,
    required this.quarkBalance,
    required this.decks,
    required this.selectedDeckId,
    required this.collection,
    required this.deckErrorMessage,
    required this.isDrawing,
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
        decks: decks,
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
              : _deckBody(context, isWide: true),
        ),
      ],
    );
  }

  Widget _narrow(BuildContext context) {
    if (selectedDeckId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${decks.length} decks',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5.sp, color: QuestPalette.dim),
                ),
              ),
              SizedBox(width: 10.w),
              Flexible(child: _wallet()),
            ],
          ),
          SizedBox(height: 12.h),
          Expanded(
            child: SingleChildScrollView(child: _deckList(isRail: false)),
          ),
        ],
      );
    }
    return _deckBody(context, showBack: true);
  }

  Widget _deckBody(
    BuildContext context, {
    bool showBack = false,
    bool isWide = false,
  }) {
    final collection = this.collection;
    if (collection == null) {
      return Column(
        children: [
          if (showBack) _backRow(_openDeckName),
          Expanded(child: Center(child: _deckLoadingOrError())),
        ],
      );
    }

    final deck = collection.deck;
    final holdings = collection.holdings;
    final canAffordDraw = deck.canAffordDraw(quarkBalance);

    if (holdings.isEmpty) {
      return Column(
        children: [
          if (showBack) _backRow(_openDeckName),
          Expanded(
            child: EmptyDeckOrganism(
              params: CollectionPresenter.emptyDeck(
                deck: deck,
                quarkBalance: quarkBalance,
                isDrawing: isDrawing,
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
        if (showBack) _backRow(_openDeckName),
        // Flexible on both sides: a Row of two plain Texts overflows the moment
        // the type scales up, which is the same defect the facts list had.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '${collection.cardsHeld} of ${deck.size} held',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5.sp, color: QuestPalette.dim),
              ),
            ),
            SizedBox(width: 10.w),
            Flexible(child: _wallet()),
          ],
        ),
        SizedBox(height: 14.h),
        Expanded(
          child: SingleChildScrollView(
            child: CardGridOrganism(
              holdings: holdings,
              cardWidth: 104,
              // Two grids, not one grid at two sizes: a phone fills the width
              // edge to edge because it has none to spare, a wide window
              // centres fixed-width cards.
              fillWidth: !isWide,
              onCardTap: onCardTap,
            ),
          ),
        ),
        SizedBox(height: 14.h),
        AppButtonAtom(
          label: 'Draw a card · ${deck.drawCost}',
          expand: true,
          isLoading: isDrawing,
          onPressed: canAffordDraw ? onDraw : null,
        ),
        // A greyed-out button with no explanation reads as broken. The empty
        // deck already says how far short the student is; a filled one owes
        // them the same answer.
        if (!canAffordDraw)
          Padding(
            padding: EdgeInsets.only(top: 9.h),
            child: Center(
              child: Text(
                CollectionPresenter.quarksShortLabel(
                  deck.quarksShortOfDraw(quarkBalance),
                ),
                style: TextStyle(fontSize: 11.sp, color: QuestPalette.amber),
              ),
            ),
          ),
      ],
    );
  }

  /// The wallet, shown wherever a student might be about to spend.
  ///
  /// It was computed from the first task and rendered nowhere, so quarks could
  /// be earned and spent entirely invisibly.
  Widget _wallet() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6.w,
          height: 6.w,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: QuestPalette.amber,
          ),
        ),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(
            CollectionPresenter.quarkBalanceLabel(quarkBalance),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5.sp, color: QuestPalette.dim),
          ),
        ),
      ],
    );
  }

  /// Taken from the deck list, because the open deck may not have loaded yet.
  String get _openDeckName =>
      decks.firstWhere((d) => d.deckId == selectedDeckId).name;

  /// The open deck before it can be shown: loading, or why it could not load.
  /// Retry opens the deck again, which reads it again.
  Widget _deckLoadingOrError() {
    final message = deckErrorMessage;
    if (message == null) return const CircularProgressIndicator();
    return ErrorWithRetryMolecule(
      message: message,
      onRetry: () => onSelectDeck(selectedDeckId!),
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
