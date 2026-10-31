import 'package:flutter/foundation.dart';

import '../../domain/entity/holding.dart';
import 'deck_row_params.dart';

/// What fills a friend's collection under its heading.
sealed class FriendCollectionBodyParams {
  const FriendCollectionBodyParams();
}

class FriendCollectionLoadingParams extends FriendCollectionBodyParams {
  const FriendCollectionLoadingParams();
}

class FriendCollectionErrorParams extends FriendCollectionBodyParams {
  final String message;
  final VoidCallback onRetry;

  const FriendCollectionErrorParams({
    required this.message,
    required this.onRetry,
  });
}

/// The friend's decks, and how complete each one is.
class FriendDeckListParams extends FriendCollectionBodyParams {
  final List<DeckRowParams> decks;

  const FriendDeckListParams({required this.decks});
}

/// One of the friend's decks, open.
class FriendDeckParams extends FriendCollectionBodyParams {
  final String deckName;

  /// Such as "4 of 6 held". Null until the deck has loaded.
  final String? heldLabel;

  /// The cards the friend holds, in the deck's order.
  final List<Holding> holdings;

  final bool isLoading;

  /// Why the deck could not load.
  final String? errorMessage;

  final VoidCallback onRetry;
  final VoidCallback onClose;
  final void Function(Holding holding) onCardTap;

  const FriendDeckParams({
    required this.deckName,
    required this.heldLabel,
    required this.holdings,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onClose,
    required this.onCardTap,
  });
}
