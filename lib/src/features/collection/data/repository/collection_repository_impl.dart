import 'package:doormer/src/core/errors/failure.dart';
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
///
/// Every draw and every shatter sends an idempotency key. When the answer is
/// lost, the key is kept, so repeating the same action sends it again and the
/// server returns its first result instead of acting twice.
///
/// It also remembers the deck list it last read, so the collection can open
/// on it at the student's next visit. Every later answer keeps its balance
/// current.
class CollectionRepositoryImpl implements CollectionRepository {
  final CollectionRemoteDataSource remoteDataSource;
  final String Function() idempotencyKeyFactory;

  /// The key of each action whose answer was lost.
  final Map<String, String> _keptKeys = {};

  ({int quarkBalance, List<DeckProgress> decks})? _lastDeckList;

  CollectionRepositoryImpl({
    required this.remoteDataSource,
    String Function()? idempotencyKeyFactory,
  }) : idempotencyKeyFactory = idempotencyKeyFactory ?? _newIdempotencyKey;

  @override
  Future<({int quarkBalance, List<DeckProgress> decks})> loadDecks() async {
    final response = await remoteDataSource.decks();
    return _lastDeckList = (
      quarkBalance: response.quarkBalance,
      decks: [for (final deck in response.decks) deck.toEntity()],
    );
  }

  @override
  ({int quarkBalance, List<DeckProgress> decks})? get lastDeckList =>
      _lastDeckList;

  @override
  void forgetLastDeckList() {
    _lastDeckList = null;
  }

  @override
  Future<({int quarkBalance, Collection collection})> loadCollection(
    String deckId,
  ) async {
    final response = await remoteDataSource.cards(deckId);
    _rememberBalance(response.quarkBalance);
    return (
      quarkBalance: response.quarkBalance,
      collection: response.toEntity(),
    );
  }

  @override
  Future<({int quarkBalance, DrawOutcome outcome})> draw(String deckId) async {
    final response = await _withKey(
      'draw $deckId',
      (key) => remoteDataSource.draw(deckId, idempotencyKey: key),
    );
    _rememberBalance(response.quarkBalance);
    return (quarkBalance: response.quarkBalance, outcome: response.toEntity());
  }

  @override
  Future<({int quarkBalance, int standardCopies, int specialCopies})>
      shatterCopy(String deckId, String cardId, CardVariant variant) async {
    final response = await _withKey(
      'shatter $deckId $cardId ${variant.name}',
      (key) => remoteDataSource.shatter(
        deckId,
        cardId,
        variant,
        idempotencyKey: key,
      ),
    );
    _rememberBalance(response.quarkBalance);
    return (
      quarkBalance: response.quarkBalance,
      standardCopies: response.standardCopies,
      specialCopies: response.specialCopies,
    );
  }

  /// Puts [quarkBalance], from the latest answer, into the remembered deck
  /// list. With no deck list remembered, there is nothing to put it in.
  void _rememberBalance(int quarkBalance) {
    final last = _lastDeckList;
    if (last == null) return;
    _lastDeckList = (quarkBalance: quarkBalance, decks: last.decks);
  }

  /// Sends [action] with its kept key, or with a fresh one. The key is kept
  /// only when the answer was lost: a timeout, no connection, or a 5xx.
  /// Every other answer retires it.
  Future<T> _withKey<T>(
    String action,
    Future<T> Function(String key) send,
  ) async {
    final key = _keptKeys.remove(action) ?? idempotencyKeyFactory();
    try {
      return await send(key);
    } on Failure catch (failure) {
      final answerLost = failure is NetworkFailure || failure is ServerFailure;
      if (answerLost) _keptKeys[action] = key;
      rethrow;
    }
  }
}

String _newIdempotencyKey() => const Uuid().v4();
