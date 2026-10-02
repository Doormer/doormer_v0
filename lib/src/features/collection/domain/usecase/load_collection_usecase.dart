import '../entity/collection.dart';
import '../repository/collection_repository.dart';

class LoadCollectionUseCase {
  final CollectionRepository repository;

  LoadCollectionUseCase(this.repository);

  Future<({int quarkBalance, Collection collection})> call(String deckId) =>
      repository.loadCollection(deckId);
}
