import 'package:equatable/equatable.dart';

import 'card_rarity.dart';
import 'collectible_card.dart';

/// What a student holds of one card. A holding only exists once at least one
/// copy has been drawn — a card never held has no holding, which is what keeps
/// the grid free of empty frames.
class Holding extends Equatable {
  final CollectibleCard card;
  final int standardCopies;
  final int specialCopies;

  const Holding({
    required this.card,
    required this.standardCopies,
    required this.specialCopies,
  });

  int get totalCopies => standardCopies + specialCopies;

  bool get hasSpecial => specialCopies > 0;

  /// The printing a shatter takes: the standard one while any is held, so the
  /// student keeps the special one. Judging this on `standardCopies > 1`
  /// instead would leave a holding of one standard and one special showing
  /// "Held 2" with the action dead.
  CardVariant get variantToShatter =>
      standardCopies > 0 ? CardVariant.standard : CardVariant.special;

  Holding copyWith({int? standardCopies, int? specialCopies}) {
    return Holding(
      card: card,
      standardCopies: standardCopies ?? this.standardCopies,
      specialCopies: specialCopies ?? this.specialCopies,
    );
  }

  @override
  List<Object?> get props => [card, standardCopies, specialCopies];
}
