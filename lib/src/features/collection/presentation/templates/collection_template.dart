import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/molecules/error_with_retry_molecule.dart';
import 'package:doormer/src/shared/design/atomic/organisms/navigation_bar_organism.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entity/collection.dart';
import '../../domain/entity/deck_progress.dart';
import '../../domain/entity/holding.dart';
import '../atoms/quark_balance_atom.dart';
import '../mapper/collection_presenter.dart';
import '../molecules/quark_balance_molecule.dart';
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

  /// Put on the open deck balance's quark dot, so a card window can aim a
  /// shatter's quark dots at it.
  final Key? quarkDotKey;

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

  /// The bar at the foot of the page, with Cards lit.
  final NavigationBarParams navigationBarParams;

  const CollectionTemplate({
    super.key,
    required this.quarkBalance,
    this.quarkDotKey,
    required this.decks,
    required this.selectedDeckId,
    required this.collection,
    required this.deckErrorMessage,
    required this.isDrawing,
    required this.onSelectDeck,
    required this.onCloseDeck,
    required this.onDraw,
    required this.onCardTap,
    required this.navigationBarParams,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= railBreakpoint;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: isWide ? _wide(context) : _narrow(context),
        ),
      ),
      bottomNavigationBar: navigationBar(navigationBarParams),
    );
  }

  /// The bar as every collection screen places it: at the foot of the
  /// Scaffold, which lays the body out above it, with home's margins.
  ///
  /// Static because the page builds the loading and error screens itself.
  static Widget navigationBar(NavigationBarParams params) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
        child: NavigationBarOrganism(params: params),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context, useKeyedBalance: true),
        SizedBox(height: 12.h),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: railWidth.w,
                child: SingleChildScrollView(child: _deckList(isRail: true)),
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: selectedDeckId == null
                    ? Center(
                        child: Text(
                          'Pick a deck to see its cards.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: QuestPalette.dim,
                          ),
                        ),
                      )
                    : _deckBody(context, isWide: true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _narrow(BuildContext context) {
    if (selectedDeckId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          SizedBox(height: 12.h),
          Expanded(
            child: SingleChildScrollView(child: _deckList(isRail: false)),
          ),
        ],
      );
    }
    return _deckBody(context, showBack: true);
  }

  Widget _header(BuildContext context, {bool useKeyedBalance = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            '${decks.length} ${decks.length == 1 ? 'deck' : 'decks'}',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5.sp, color: QuestPalette.dim),
          ),
        ),
        SizedBox(width: 10.w),
        Flexible(
          child: useKeyedBalance
              ? QuarkBalanceMolecule(
                  quarkBalance: quarkBalance,
                  dotKey: quarkDotKey,
                )
              : QuarkBalanceAtom(quarkBalance: quarkBalance),
        ),
      ],
    );
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
            if (!isWide) ...[
              SizedBox(width: 10.w),
              Flexible(
                child: QuarkBalanceMolecule(
                  quarkBalance: quarkBalance,
                  dotKey: quarkDotKey,
                ),
              ),
            ],
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
          label: CollectionPresenter.drawLabel(deck.drawCost),
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
