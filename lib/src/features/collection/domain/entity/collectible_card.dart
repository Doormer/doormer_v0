// lib/src/features/collection/domain/entity/collectible_card.dart
import 'package:equatable/equatable.dart';

import 'card_rarity.dart';

/// One card in a deck. Identity is the id alone — a card's presentation may be
/// re-authored without it becoming a different card.
class CollectibleCard extends Equatable {
  final String id;
  final String name;
  final String deckId;
  final Rarity rarity;

  /// Free text such as `Small` or `Capital`. Deliberately not an enum: decks
  /// are unbounded and a future deck may not have hulls at all.
  final String scaleLabel;

  final String artAsset;
  final String description;

  const CollectibleCard({
    required this.id,
    required this.name,
    required this.deckId,
    required this.rarity,
    required this.scaleLabel,
    required this.artAsset,
    required this.description,
  });

  @override
  List<Object?> get props => [id];
}
