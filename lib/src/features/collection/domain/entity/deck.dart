import 'package:equatable/equatable.dart';

import 'card_rarity.dart';
import 'collectible_card.dart';

/// A named set of cards. Deck size is whatever the deck says it is — nothing in
/// the feature may assume a fixed number of cards or a fixed number of decks.
class Deck extends Equatable {
  final String id;
  final String name;
  final List<CollectibleCard> cards;

  const Deck({required this.id, required this.name, required this.cards});

  int get size => cards.length;

  /// How many cards of each rarity the deck contains. This describes the deck's
  /// *contents*, not the chance of drawing them — the empty state shows it, and
  /// it must never be presented as odds.
  Map<Rarity, int> get rarityMix {
    final mix = <Rarity, int>{for (final r in Rarity.values) r: 0};
    for (final card in cards) {
      mix[card.rarity] = mix[card.rarity]! + 1;
    }
    return mix;
  }

  @override
  List<Object?> get props => [id];
}
