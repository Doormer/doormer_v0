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

  final String artUrl;

  /// Quarks paid for shattering one copy of each printing. They come with the
  /// card from the server, so the app never works them out for itself.
  final int standardShatterQuarks;
  final int specialShatterQuarks;

  final String description;

  const CollectibleCard({
    required this.id,
    required this.name,
    required this.deckId,
    required this.rarity,
    required this.scaleLabel,
    required this.artUrl,
    required this.standardShatterQuarks,
    required this.specialShatterQuarks,
    required this.description,
  });

  int shatterQuarksFor(CardVariant variant) => variant == CardVariant.special
      ? specialShatterQuarks
      : standardShatterQuarks;

  @override
  List<Object?> get props => [id];
}
