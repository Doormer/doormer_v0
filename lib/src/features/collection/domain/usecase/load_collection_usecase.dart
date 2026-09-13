import '../entity/collection.dart';
import '../repository/collection_repository.dart';

class LoadCollectionUseCase {
  final CollectionRepository repository;

  LoadCollectionUseCase(this.repository);

  Future<Collection> call() => repository.load();
}
