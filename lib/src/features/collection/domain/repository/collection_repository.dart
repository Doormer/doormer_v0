import '../entity/card_rarity.dart';
import '../entity/collection.dart';
import '../entity/draw_outcome.dart';

abstract class CollectionRepository {
  /// Reads the collection for the first time.
  Future<Collection> load();

  /// The collection as it stands after any draws and conversions this session.
  Future<Collection> current();

  /// Spends [Collection.drawCost] and advances the replayed sequence.
  Future<DrawOutcome> draw(String deckId);

  /// Trades one held copy for points.
  Future<Collection> convertCopy(String cardId, CardVariant variant);
}
