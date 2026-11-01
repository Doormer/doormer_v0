import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/card_picture_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/level_icons_atom.dart';
import 'package:doormer/src/shared/design/atomic/molecules/error_with_retry_molecule.dart';
import 'package:doormer/src/shared/design/atomic/molecules/page_heading_molecule.dart';
import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../organisms/card_grid_organism.dart';
import '../organisms/deck_list_organism.dart';
import '../params/friend_collection_body_params.dart';

/// A friend's collection, headed with their picture, "Sam's cards" and their
/// level's icons: their decks, then the cards of the one open. There are no
/// quarks, draws or shatters, and nothing compares it with the student's
/// own. It sits inside the Profile tab, above the nav bar.
class FriendCollectionTemplate extends StatelessWidget {
  /// Wider than this, cards keep their size and centre, as on Cards.
  static const double wideBreakpoint = 700;

  final String title;

  /// The friend's, for the picture beside the title. Null until the friend
  /// is known.
  final String? nickname;

  /// Null when the friend has no picture.
  final String? artUrl;

  /// The friend's level, drawn beside the title. Null below level 1, and
  /// until the friend is known.
  final Level? level;

  /// What screen readers hear for the level's icons, such as `Level 6`.
  final String? levelLabel;

  final FriendCollectionBodyParams body;
  final VoidCallback onBack;

  const FriendCollectionTemplate({
    super.key,
    required this.title,
    required this.nickname,
    required this.artUrl,
    this.level,
    this.levelLabel,
    required this.body,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final nickname = this.nickname;
    final level = this.level;
    final isWide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeadingMolecule(
              title: title,
              onBack: onBack,
              leading: nickname == null
                  ? null
                  : CardPictureAtom(name: nickname, artUrl: artUrl, size: 32.w),
              trailing: level == null
                  ? null
                  : LevelIconsAtom(
                      suns: level.suns,
                      moons: level.moons,
                      stars: level.stars,
                      size: 18.w,
                      semanticLabel: levelLabel,
                    ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
                child: _content(isWide: isWide),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content({required bool isWide}) {
    return switch (body) {
      FriendCollectionLoadingParams() => const Center(
          child: CircularProgressIndicator(color: QuestPalette.violet),
        ),
      FriendCollectionErrorParams(:final message, :final onRetry) => Center(
          child: ErrorWithRetryMolecule(
            message: message,
            onRetry: onRetry,
            retryLabel: 'Try again',
          ),
        ),
      FriendDeckListParams(:final decks) => SingleChildScrollView(
          child: DeckListOrganism(rows: decks),
        ),
      FriendDeckParams deck => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _backRow(deck),
            Expanded(child: _deckBody(deck, isWide: isWide)),
          ],
        ),
    };
  }

  Widget _deckBody(FriendDeckParams deck, {required bool isWide}) {
    final errorMessage = deck.errorMessage;
    if (deck.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return Center(
        child: ErrorWithRetryMolecule(
          message: errorMessage,
          onRetry: deck.onRetry,
          retryLabel: 'Try again',
        ),
      );
    }
    if (deck.holdings.isEmpty) {
      return Center(
        child: Text(
          'No cards from this deck yet.',
          style: TextStyle(fontSize: 13.sp, color: QuestPalette.muted),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (deck.heldLabel case final heldLabel?)
          Text(
            heldLabel,
            style: TextStyle(fontSize: 11.5.sp, color: QuestPalette.dim),
          ),
        SizedBox(height: 14.h),
        Expanded(
          child: SingleChildScrollView(
            child: CardGridOrganism(
              holdings: deck.holdings,
              cardWidth: 104,
              fillWidth: !isWide,
              onCardTap: deck.onCardTap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _backRow(FriendDeckParams deck) {
    final mutedStyle = TextStyle(fontSize: 12.sp, color: QuestPalette.muted);
    return Padding(
      padding: EdgeInsets.only(bottom: 13.h),
      child: InkWell(
        key: const Key('friend_deck_back'),
        onTap: deck.onClose,
        child: Row(
          children: [
            Icon(Icons.arrow_back, size: 16.w, color: QuestPalette.markerLine),
            SizedBox(width: 7.w),
            Text('Decks', style: mutedStyle),
            SizedBox(width: 7.w),
            Text('·', style: mutedStyle),
            SizedBox(width: 7.w),
            Flexible(
              child: Text(
                deck.deckName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: QuestPalette.cream,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
