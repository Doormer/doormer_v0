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

  /// One cursor per deck. A single shared cursor would let a draw from one deck
  /// award a card belonging to another, because the bundled sequence interleaves
  /// decks.
  final Map<String, int> _cursors = <String, int>{};

  CollectionRepositoryImpl({required this.dataSource});

  @override
  Future<Collection> load() async {
    final collection = await dataSource.loadCollection();
    _collection = collection;
    _sequence = await dataSource.loadDrawSequence();
    _cursors.clear();
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
      throw ValidationFailure("You don't have enough quarks for a draw.");
    }

    // A draw is always *from* a deck, so only that deck's steps are eligible.
    final deckSteps =
        _sequence.where((s) => s.card.deckId == deckId).toList(growable: false);
    if (deckSteps.isEmpty) {
      throw ValidationFailure('There is nothing left to draw.');
    }

    // Wrap rather than run dry: this is a review build and someone will draw
    // more times than the sequence has entries.
    final cursor = _cursors[deckId] ?? 0;
    final step = deckSteps[cursor % deckSteps.length];
    _cursors[deckId] = cursor + 1;

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
      quarkBalance: collection.quarkBalance - collection.drawCost,
    );

    // The result is derived from what was actually held a moment ago, not taken
    // from the asset. On the second lap of the sequence the asset's own label is
    // stale — a card it calls `newCard` is by then already held — and a reveal
    // reading "A new one" above a badge reading x2 is plainly wrong.
    final DrawResult result;
    if (existing == null) {
      result = DrawResult.newCard;
    } else if (step.variant == CardVariant.special && !existing.hasSpecial) {
      result = DrawResult.upgrade;
    } else {
      result = DrawResult.duplicate;
    }

    return DrawOutcome(
      card: step.card,
      variant: step.variant,
      result: result,
      copiesAfter: updated.totalCopies,
    );
  }

  @override
  Future<Collection> shatterCopy(String cardId, CardVariant variant) async {
    final collection = await current();
    final holding = collection.holdingsByCardId[cardId];

    if (holding == null) {
      throw ValidationFailure('That card is not held.');
    }

    final isSpecial = variant == CardVariant.special;
    final available =
        isSpecial ? holding.specialCopies : holding.standardCopies;
    if (available < 1) {
      throw ValidationFailure("You don't have a spare copy of that card.");
    }

    final shatterQuarks = holding.card.shatterQuarksFor(variant);

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
      quarkBalance: collection.quarkBalance + shatterQuarks,
    );
    return _collection!;
  }
}
