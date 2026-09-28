// lib/src/features/collection/domain/entity/card_rarity.dart

/// How scarce a card is. The values come from the verified economy simulation
/// and are the same three the Go engine uses.
enum Rarity {
  common(5),
  uncommon(11),
  rare(19);

  const Rarity(this.standardShatterQuarks);

  /// Quarks paid for shattering one standard copy.
  final int standardShatterQuarks;

  /// A special copy is worth exactly double. Kept derived rather than stored so
  /// the two can never drift apart.
  int get specialShatterQuarks => standardShatterQuarks * 2;
}

/// Which printing of a card this is. `special` is the upgraded finish; both are
/// kept when a student holds them, and neither is ever destroyed automatically.
enum CardVariant { standard, special }
