// lib/src/features/collection/presentation/bloc/collection_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entity/card_rarity.dart';
import '../../domain/entity/collection.dart';
import '../../domain/entity/draw_outcome.dart';
import '../../domain/usecase/convert_copy_usecase.dart';
import '../../domain/usecase/draw_card_usecase.dart';
import '../../domain/usecase/load_collection_usecase.dart';

part 'collection_event.dart';
part 'collection_state.dart';

class CollectionBloc extends Bloc<CollectionEvent, CollectionState> {
  final LoadCollectionUseCase loadCollection;
  final DrawCardUseCase drawCard;
  final ConvertCopyUseCase convertCopy;

  CollectionBloc({
    required this.loadCollection,
    required this.drawCard,
    required this.convertCopy,
  }) : super(const CollectionLoading()) {
    on<CollectionStarted>(_onStarted);
    on<DeckSelected>(_onDeckSelected);
    on<DeckClosed>(_onDeckClosed);
    on<DrawRequested>(_onDrawRequested);
    on<RevealDismissed>(_onRevealDismissed);
    on<ConvertCopyRequested>(_onConvertCopyRequested);
  }

  Future<void> _onStarted(
    CollectionStarted event,
    Emitter<CollectionState> emit,
  ) async {
    emit(const CollectionLoading());
    try {
      emit(CollectionReady(collection: await loadCollection()));
    } on Failure catch (failure) {
      emit(CollectionFailed(failure.message));
    } catch (e, stackTrace) {
      AppLogger.error('Collection load failed',
          error: e, stackTrace: stackTrace);
      emit(const CollectionFailed('We could not open your collection.'));
    }
  }

  void _onDeckSelected(DeckSelected event, Emitter<CollectionState> emit) {
    final ready = state;
    if (ready is! CollectionReady) return;
    emit(ready.copyWith(selectedDeckId: event.deckId));
  }

  void _onDeckClosed(DeckClosed event, Emitter<CollectionState> emit) {
    final ready = state;
    if (ready is! CollectionReady) return;
    emit(ready.copyWith(clearSelectedDeck: true, clearReveal: true));
  }

  Future<void> _onDrawRequested(
    DrawRequested event,
    Emitter<CollectionState> emit,
  ) async {
    final ready = state;
    if (ready is! CollectionReady) return;

    // A second tap while a draw is in flight must not spend twice.
    if (ready.isDrawing) return;

    final deckId = ready.selectedDeckId;
    if (deckId == null) return;

    emit(ready.copyWith(isDrawing: true, clearReveal: true));
    try {
      final result = await drawCard(deckId);
      // Merge into the state as it stands NOW, not the snapshot taken before
      // the await. Bloc handlers run concurrently, so a DeckClosed or
      // RevealDismissed that arrived mid-draw would otherwise be silently
      // undone — the deck would reopen itself under the student.
      final latest = state;
      if (latest is! CollectionReady) return;
      emit(latest.copyWith(
        collection: result.collection,
        isDrawing: false,
        pendingReveal: result.outcome,
      ));
    } on Failure catch (failure) {
      final latest = state;
      if (latest is! CollectionReady) return;
      emit(latest.copyWith(
        isDrawing: false,
        clearReveal: true,
        errorMessage: failure.message,
        clearError: false,
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

  Future<void> _onConvertCopyRequested(
    ConvertCopyRequested event,
    Emitter<CollectionState> emit,
  ) async {
    final ready = state;
    if (ready is! CollectionReady) return;
    try {
      final collection = await convertCopy(event.cardId, event.variant);
      // Same reason as the draw: merge into the latest state so a reveal the
      // student dismissed mid-convert does not come back.
      final latest = state;
      if (latest is! CollectionReady) return;
      emit(latest.copyWith(collection: collection));
    } on Failure catch (failure) {
      final latest = state;
      if (latest is! CollectionReady) return;
      emit(latest.copyWith(errorMessage: failure.message, clearError: false));
    }
  }
}
