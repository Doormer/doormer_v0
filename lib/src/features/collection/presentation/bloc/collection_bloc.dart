// lib/src/features/collection/presentation/bloc/collection_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entity/card_rarity.dart';
import '../../domain/entity/collection.dart';
import '../../domain/entity/deck_progress.dart';
import '../../domain/entity/draw_outcome.dart';
import '../../domain/usecase/draw_card_usecase.dart';
import '../../domain/usecase/load_collection_usecase.dart';
import '../../domain/usecase/load_decks_usecase.dart';
import '../../domain/usecase/shatter_copy_usecase.dart';

part 'collection_event.dart';
part 'collection_state.dart';

/// Bloc handlers run concurrently, so every handler that awaits applies its
/// answer to the state as it stands *after* the await, never to the snapshot
/// taken before it. An answer about a deck that is no longer open updates the
/// balance and the deck list, but never the open deck: passing a null
/// `collection` to `copyWith` keeps what the open deck is showing.
class CollectionBloc extends Bloc<CollectionEvent, CollectionState> {
  static const _somethingWentWrong = 'Something went wrong. Try again.';

  final LoadDecksUseCase loadDecks;
  final LoadCollectionUseCase loadCollection;
  final DrawCardUseCase drawCard;
  final ShatterCopyUseCase shatterCopy;

  CollectionBloc({
    required this.loadDecks,
    required this.loadCollection,
    required this.drawCard,
    required this.shatterCopy,
  }) : super(_openingState(loadDecks.lastDeckList)) {
    on<CollectionStarted>(_onStarted);
    on<DeckSelected>(_onDeckSelected);
    on<DeckClosed>(_onDeckClosed);
    on<DrawRequested>(_onDrawRequested);
    on<RevealDismissed>(_onRevealDismissed);
    on<ShatterCopyRequested>(_onShatterCopyRequested);
  }

  /// The remembered deck list, so a visit after the first opens straight onto
  /// it. It has to be the first state, not an emit: a handler runs only after
  /// the first frame, and that frame would show the spinner.
  static CollectionState _openingState(
    ({int quarkBalance, List<DeckProgress> decks})? lastDeckList,
  ) =>
      lastDeckList == null
          ? const CollectionLoading()
          : CollectionReady(
              quarkBalance: lastDeckList.quarkBalance,
              decks: lastDeckList.decks,
            );

  Future<void> _onStarted(
    CollectionStarted event,
    Emitter<CollectionState> emit,
  ) async {
    final opened = state;
    if (opened is CollectionReady) {
      // Opened on the remembered deck list: read afresh behind it, and show
      // the answer only if the student hasn't changed anything since.
      // Whatever they opened reads afresh itself.
      try {
        final list = await loadDecks();
        if (state != opened) return;
        emit(CollectionReady(
            quarkBalance: list.quarkBalance, decks: list.decks));
      } catch (e, stackTrace) {
        // The remembered deck list stays up.
        AppLogger.info(
            'Deck list not refreshed: ${_messageFor(e, stackTrace)}');
      }
      return;
    }

    emit(const CollectionLoading());
    try {
      final list = await loadDecks();
      emit(CollectionReady(quarkBalance: list.quarkBalance, decks: list.decks));
    } catch (e, stackTrace) {
      emit(CollectionError(_messageFor(e, stackTrace)));
    }
  }

  Future<void> _onDeckSelected(
    DeckSelected event,
    Emitter<CollectionState> emit,
  ) async {
    final ready = state;
    if (ready is! CollectionReady) return;
    emit(ready.copyWith(
      selectedDeckId: event.deckId,
      clearCollection: true,
      clearDeckError: true,
    ));

    try {
      final read = await _readDeck(event.deckId);
      final latest = state;
      if (latest is! CollectionReady) return;
      emit(latest.copyWith(
        quarkBalance: read.quarkBalance,
        decks: read.decks,
        collection:
            latest.selectedDeckId == event.deckId ? read.collection : null,
      ));
    } catch (e, stackTrace) {
      final message = _messageFor(e, stackTrace);
      final latest = state;
      if (latest is! CollectionReady) return;
      if (latest.selectedDeckId != event.deckId) return;
      emit(latest.copyWith(deckErrorMessage: message));
    }
  }

  void _onDeckClosed(DeckClosed event, Emitter<CollectionState> emit) {
    final ready = state;
    if (ready is! CollectionReady) return;
    emit(ready.copyWith(
      clearSelectedDeck: true,
      clearCollection: true,
      clearDeckError: true,
      clearReveal: true,
    ));
  }

  Future<void> _onDrawRequested(
    DrawRequested event,
    Emitter<CollectionState> emit,
  ) async {
    final ready = state;
    if (ready is! CollectionReady) return;

    // One action at a time: a second tap must not spend twice, and a draw's
    // read must not overwrite the counts from a newer shatter.
    if (ready.isDrawing || ready.isShattering) return;

    // Nothing to draw from until the open deck has loaded.
    final deck = ready.collection?.deck;
    if (deck == null) return;

    emit(ready.copyWith(isDrawing: true, clearReveal: true));

    final ({int quarkBalance, DrawOutcome outcome}) drawn;
    try {
      drawn = await drawCard(deck.id);
    } catch (e, stackTrace) {
      final message = _messageFor(e, stackTrace);
      final latest = state;
      if (latest is! CollectionReady) return;
      emit(latest.copyWith(isDrawing: false, errorMessage: message));
      return;
    }

    // The card is paid for, so the reveal plays even when the read fails.
    // `isDrawing` stays set until then, so the button keeps its spinner.
    try {
      final read = await _readDeck(deck.id);
      final latest = state;
      if (latest is! CollectionReady) return;
      emit(latest.copyWith(
        isDrawing: false,
        quarkBalance: read.quarkBalance,
        decks: read.decks,
        collection: latest.selectedDeckId == deck.id ? read.collection : null,
        pendingReveal: PendingReveal(
          outcome: drawn.outcome,
          deckName: deck.name,
          collectionAfterDraw: read.collection,
        ),
      ));
    } catch (e, stackTrace) {
      final message = _messageFor(e, stackTrace);
      final latest = state;
      if (latest is! CollectionReady) return;
      final isOpen = latest.selectedDeckId == deck.id;
      emit(latest.copyWith(
        isDrawing: false,
        quarkBalance: drawn.quarkBalance,
        clearCollection: isOpen,
        deckErrorMessage: isOpen ? message : null,
        pendingReveal: PendingReveal(
          outcome: drawn.outcome,
          deckName: deck.name,
        ),
      ));
    }
  }

  void _onRevealDismissed(
    RevealDismissed event,
    Emitter<CollectionState> emit,
  ) {
    final ready = state;
    if (ready is! CollectionReady) return;
    emit(ready.copyWith(clearReveal: true));
  }

  Future<void> _onShatterCopyRequested(
    ShatterCopyRequested event,
    Emitter<CollectionState> emit,
  ) async {
    final ready = state;
    if (ready is! CollectionReady) return;
    if (ready.isDrawing || ready.isShattering) return;

    final deckId = ready.collection?.deck.id;
    if (deckId == null) return;

    emit(ready.copyWith(isShattering: true));
    try {
      final shattered = await shatterCopy(deckId, event.cardId, event.variant);
      final latest = state;
      if (latest is! CollectionReady) return;
      final open = latest.collection;
      // Nothing is re-read: the answer carries everything that changes, and
      // the deck list cannot change, because the last copy of a card can never
      // be shattered.
      emit(latest.copyWith(
        isShattering: false,
        quarkBalance: shattered.quarkBalance,
        collection: open != null && open.deck.id == deckId
            ? open.withCopies(
                event.cardId,
                standardCopies: shattered.standardCopies,
                specialCopies: shattered.specialCopies,
              )
            : null,
      ));
    } catch (e, stackTrace) {
      final message = _messageFor(e, stackTrace);
      final latest = state;
      if (latest is! CollectionReady) return;
      emit(latest.copyWith(isShattering: false, errorMessage: message));
    }
  }

  /// Reads one deck and then the deck list, so the list shown beside the deck
  /// can never lag behind it. Either read failing fails both.
  Future<({int quarkBalance, List<DeckProgress> decks, Collection collection})>
      _readDeck(String deckId) async {
    final opened = await loadCollection(deckId);
    final list = await loadDecks();
    return (
      quarkBalance: opened.quarkBalance,
      decks: list.decks,
      collection: opened.collection,
    );
  }

  /// A [Failure] already carries a message a student can read. Anything else
  /// is a bug: it is logged, and the student is told something plain.
  static String _messageFor(Object error, StackTrace stackTrace) {
    if (error is Failure) return error.message;
    AppLogger.error('Collection failed unexpectedly',
        error: error, stackTrace: stackTrace);
    return _somethingWentWrong;
  }
}
