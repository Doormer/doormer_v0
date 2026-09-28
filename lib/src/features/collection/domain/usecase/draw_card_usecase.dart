import '../entity/collection.dart';
import '../entity/draw_outcome.dart';
import '../repository/collection_repository.dart';

/// Returns the outcome **and** the collection it produced.
///
/// The outcome alone is not enough: a draw spends quarks and adds a copy, so a
/// caller given only the outcome would render a stale wallet and a grid missing
/// the card that was just drawn. Reading `current()` here rather than `load()`
/// matters — `load()` resets the replay cursor.
class DrawCardUseCase {
  final CollectionRepository repository;

  DrawCardUseCase(this.repository);

  Future<({DrawOutcome outcome, Collection collection})> call(
    String deckId,
  ) async {
    final outcome = await repository.draw(deckId);
    return (outcome: outcome, collection: await repository.current());
  }
}
