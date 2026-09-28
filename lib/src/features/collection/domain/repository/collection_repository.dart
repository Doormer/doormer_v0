import '../entity/card_rarity.dart';
import '../entity/collection.dart';
import '../entity/draw_outcome.dart';

abstract class CollectionRepository {
  /// Reads the collection for the first time.
  Future<Collection> load();

  /// The collection as it stands after any draws and shatters this session.
  Future<Collection> current();

  /// Spends [Collection.drawCost] and advances the replayed sequence.
  Future<DrawOutcome> draw(String deckId);

  /// Shatters one held copy for quarks.
  Future<Collection> shatterCopy(String cardId, CardVariant variant);
}
