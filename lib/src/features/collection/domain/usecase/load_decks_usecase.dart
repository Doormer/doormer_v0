import '../entity/deck_progress.dart';
import '../repository/collection_repository.dart';

class LoadDecksUseCase {
  final CollectionRepository repository;

  LoadDecksUseCase(this.repository);

  Future<({int quarkBalance, List<DeckProgress> decks})> call() =>
      repository.loadDecks();

  /// The deck list as it was last read. See
  /// [CollectionRepository.lastDeckList].
  ({int quarkBalance, List<DeckProgress> decks})? get lastDeckList =>
      repository.lastDeckList;
}
