import '../entity/card_rarity.dart';
import '../entity/collection.dart';
import '../repository/collection_repository.dart';

class ShatterCopyUseCase {
  final CollectionRepository repository;

  ShatterCopyUseCase(this.repository);

  Future<Collection> call(String cardId, CardVariant variant) =>
      repository.shatterCopy(cardId, variant);
}
