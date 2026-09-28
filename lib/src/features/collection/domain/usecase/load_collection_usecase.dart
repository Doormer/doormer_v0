import '../entity/collection.dart';
import '../repository/collection_repository.dart';

class LoadCollectionUseCase {
  final CollectionRepository repository;

  LoadCollectionUseCase(this.repository);

  /// Deliberately `current()`, not `load()`.
  ///
  /// The page raises `CollectionStarted` on every mount, and `load()` re-reads
  /// the asset, replaces the collection and clears every per-deck cursor — so
  /// leaving the collection and coming back would silently discard the
  /// student's quarks, holdings and place in the sequence. `current()` loads
  /// on first use and returns the live session afterwards.
  Future<Collection> call() => repository.current();
}
