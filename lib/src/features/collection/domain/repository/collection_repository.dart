import '../entity/card_rarity.dart';
import '../entity/collection.dart';
import '../entity/deck_progress.dart';
import '../entity/draw_outcome.dart';

/// The student's collection, as the server holds it. Every read and every
/// action answers with the student's quark balance.
///
/// Every method throws a `Failure` whose message a student can read.
abstract class CollectionRepository {
  Future<({int quarkBalance, List<DeckProgress> decks})> loadDecks();

  /// The deck list as it was last read, with the quark balance from the
  /// latest answer of any kind, so the collection can open on it while it
  /// reads afresh. Null before the first read and after [forgetLastDeckList].
  ({int quarkBalance, List<DeckProgress> decks})? get lastDeckList;

  /// Drops [lastDeckList]. Whoever signs in next may be a different student.
  void forgetLastDeckList();

  /// One deck, with every card in it, held or not.
  Future<({int quarkBalance, Collection collection})> loadCollection(
    String deckId,
  );

  /// Spends the deck's draw cost on one card from it.
  Future<({int quarkBalance, DrawOutcome outcome})> draw(String deckId);

  /// Shatters one copy of [variant] for quarks, and answers with the copies of
  /// the card that are left.
  Future<({int quarkBalance, int standardCopies, int specialCopies})>
      shatterCopy(String deckId, String cardId, CardVariant variant);
}
