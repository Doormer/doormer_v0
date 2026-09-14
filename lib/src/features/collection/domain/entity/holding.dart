import 'package:equatable/equatable.dart';

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
