import '../entity/card_rarity.dart';
import '../repository/collection_repository.dart';

class ShatterCopyUseCase {
  final CollectionRepository repository;

  ShatterCopyUseCase(this.repository);

  Future<({int quarkBalance, int standardCopies, int specialCopies})> call(
    String deckId,
    String cardId,
    CardVariant variant,
  ) =>
      repository.shatterCopy(deckId, cardId, variant);
}
