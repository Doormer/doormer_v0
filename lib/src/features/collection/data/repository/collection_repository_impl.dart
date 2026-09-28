import 'package:uuid/uuid.dart';

import '../../domain/entity/card_rarity.dart';
import '../../domain/entity/collection.dart';
import '../../domain/entity/deck_progress.dart';
import '../../domain/entity/draw_outcome.dart';
import '../../domain/repository/collection_repository.dart';
import '../datasource/collection_remote_datasource.dart';

/// Turns the API's responses into the domain's terms. The data source has
/// already turned every problem into a `Failure` a student can read, so
/// failures pass straight through.
class CollectionRepositoryImpl implements CollectionRepository {
  final CollectionRemoteDataSource remoteDataSource;
  final String Function() idempotencyKeyFactory;

  CollectionRepositoryImpl({
    required this.remoteDataSource,
    String Function()? idempotencyKeyFactory,
  }) : idempotencyKeyFactory = idempotencyKeyFactory ?? _newIdempotencyKey;

  @override
  Future<({int quarkBalance, List<DeckProgress> decks})> loadDecks() async {
    final response = await remoteDataSource.decks();
    return (
      quarkBalance: response.quarkBalance,
      decks: [for (final deck in response.decks) deck.toEntity()],
    );
  }

  @override
  Future<({int quarkBalance, Collection collection})> loadCollection(
    String deckId,
  ) async {
    final response = await remoteDataSource.cards(deckId);
    return (
      quarkBalance: response.quarkBalance,
      collection: response.toEntity(),
    );
  }

  @override
  Future<({int quarkBalance, DrawOutcome outcome})> draw(String deckId) async {
    final response = await remoteDataSource.draw(
      deckId,
      idempotencyKey: idempotencyKeyFactory(),
    );
    return (quarkBalance: response.quarkBalance, outcome: response.toEntity());
  }

  @override
  Future<({int quarkBalance, int standardCopies, int specialCopies})>
      shatterCopy(String deckId, String cardId, CardVariant variant) async {
    final response = await remoteDataSource.shatter(
      deckId,
      cardId,
      variant,
      idempotencyKey: idempotencyKeyFactory(),
    );
    return (
      quarkBalance: response.quarkBalance,
      standardCopies: response.standardCopies,
      specialCopies: response.specialCopies,
    );
  }
}

String _newIdempotencyKey() => const Uuid().v4();
