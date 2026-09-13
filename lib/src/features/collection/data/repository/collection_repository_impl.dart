import 'package:doormer/src/core/errors/failure.dart';

import '../../domain/entity/card_rarity.dart';
import '../../domain/entity/collection.dart';
import '../../domain/entity/draw_outcome.dart';
import '../../domain/entity/holding.dart';
import '../../domain/repository/collection_repository.dart';
import '../datasource/collection_local_datasource.dart';

/// Holds the session's mutated collection in memory.
///
/// There is no backend and no persistence in this build, so everything a
/// student does is lost on reload. That is deliberate and is the single place
/// this feature is openly a prototype.
class CollectionRepositoryImpl implements CollectionRepository {
  final CollectionLocalDataSource dataSource;

  Collection? _collection;
  List<DrawOutcome> _sequence = const [];
  int _cursor = 0;

  CollectionRepositoryImpl({required this.dataSource});

  @override
  Future<Collection> load() async {
    final collection = await dataSource.loadCollection();
    _collection = collection;
    _sequence = await dataSource.loadDrawSequence();
    _cursor = 0;
    return collection;
  }

  @override
  Future<Collection> current() async {
    return _collection ?? await load();
  }

  @override
  Future<DrawOutcome> draw(String deckId) async {
    final collection = await current();

    if (!collection.canAffordDraw) {
      throw ValidationFailure('Not enough points for a draw.');
    }
    if (_sequence.isEmpty) {
      throw ValidationFailure('There is nothing left to draw.');
    }

    // Wrap rather than run dry: this is a review build and someone will draw
    // more times than the sequence has entries.
    final step = _sequence[_cursor % _sequence.length];
    _cursor++;

    final existing = collection.holdingsByCardId[step.card.id];
    final Holding updated;
    if (existing == null) {
      updated = Holding(
        card: step.card,
        standardCopies: step.variant == CardVariant.standard ? 1 : 0,
        specialCopies: step.variant == CardVariant.special ? 1 : 0,
      );
    } else if (step.variant == CardVariant.special) {
      updated = existing.copyWith(specialCopies: existing.specialCopies + 1);
    } else {
      updated = existing.copyWith(standardCopies: existing.standardCopies + 1);
    }

    final holdings = Map<String, Holding>.from(collection.holdingsByCardId)
      ..[step.card.id] = updated;

    _collection = collection.copyWith(
      holdingsByCardId: holdings,
      walletPoints: collection.walletPoints - collection.drawCost,
    );

    return DrawOutcome(
      card: step.card,
      variant: step.variant,
      kind: step.kind,
      copiesAfter: updated.totalCopies,
    );
  }

  @override
  Future<Collection> convertCopy(String cardId, CardVariant variant) async {
    final collection = await current();
    final holding = collection.holdingsByCardId[cardId];

    if (holding == null) {
      throw ValidationFailure('That card is not held.');
    }

    final isSpecial = variant == CardVariant.special;
    final available = isSpecial ? holding.specialCopies : holding.standardCopies;
    if (available < 1) {
      throw ValidationFailure('There is no copy of that kind to trade.');
    }

    final payout = isSpecial
        ? holding.card.rarity.specialConversionValue
        : holding.card.rarity.conversionValue;

    final reduced = isSpecial
        ? holding.copyWith(specialCopies: holding.specialCopies - 1)
        : holding.copyWith(standardCopies: holding.standardCopies - 1);

    final holdings = Map<String, Holding>.from(collection.holdingsByCardId);
    if (reduced.totalCopies == 0) {
      holdings.remove(cardId);
    } else {
      holdings[cardId] = reduced;
    }

    _collection = collection.copyWith(
      holdingsByCardId: holdings,
      walletPoints: collection.walletPoints + payout,
    );
    return _collection!;
  }
}
