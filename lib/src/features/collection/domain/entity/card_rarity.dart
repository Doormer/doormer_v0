// lib/src/features/collection/domain/entity/card_rarity.dart

/// How scarce a card is: the same three the Go engine uses. What a copy is
/// worth when shattered comes with each card, so it is not kept here.
enum Rarity { common, uncommon, rare }

/// Which printing of a card this is. `special` is the upgraded finish; both are
/// kept when a student holds them, and neither is ever destroyed automatically.
enum CardVariant { standard, special }
