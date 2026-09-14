import '../entity/card_rarity.dart';
import '../entity/collection.dart';
import '../repository/collection_repository.dart';

class ConvertCopyUseCase {
  final CollectionRepository repository;

  ConvertCopyUseCase(this.repository);

  Future<Collection> call(String cardId, CardVariant variant) =>
      repository.convertCopy(cardId, variant);
}
