// lib/src/features/collection/domain/entity/draw_outcome.dart
import 'package:equatable/equatable.dart';

import 'card_rarity.dart';
import 'collectible_card.dart';

/// What a draw turned out to be.
///
/// The headlines are the feature's whole voice and live here so no widget can
/// improvise one. They are generic on purpose: a deck of creatures has to read
/// as naturally as a deck of spacecraft, so the card supplies the specifics.
///
/// `duplicate` is the engine's word for the third case and must never reach a
/// student — it is clinical, and it names the thing as redundant.
enum DrawResult {
  newCard('New card!'),
  upgrade('Now special'),
  duplicate('Another one');

  const DrawResult(this.headline);

  final String headline;
}

class DrawOutcome extends Equatable {
  final CollectibleCard card;
  final CardVariant variant;
  final DrawResult result;

  /// Copies held *after* this draw. Drives the fan and the badge.
  final int copiesAfter;

  const DrawOutcome({
    required this.card,
    required this.variant,
    required this.result,
    required this.copiesAfter,
  });

  @override
  List<Object?> get props => [card, variant, result, copiesAfter];
}
