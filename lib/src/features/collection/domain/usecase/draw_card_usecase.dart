import '../entity/draw_outcome.dart';
import '../repository/collection_repository.dart';

class DrawCardUseCase {
  final CollectionRepository repository;

  DrawCardUseCase(this.repository);

  Future<({int quarkBalance, DrawOutcome outcome})> call(String deckId) =>
      repository.draw(deckId);
}
