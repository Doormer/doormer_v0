// lib/src/features/collection/presentation/pages/collection_page.dart
import 'package:doormer/src/core/di/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/collection_bloc.dart';
import '../organisms/card_detail_organism.dart';
import '../organisms/card_reveal_organism.dart';
import '../params/card_detail_params.dart';
import '../params/reveal_params.dart';
import '../mapper/collection_presenter.dart';
import '../templates/collection_template.dart';

/// The only widget in this feature that touches `flutter_bloc`.
class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          serviceLocator<CollectionBloc>()..add(const CollectionStarted()),
      child: const _CollectionView(),
    );
  }
}

class _CollectionView extends StatelessWidget {
  const _CollectionView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CollectionBloc, CollectionState>(
      // A draw or shatter that fails was previously silent: the bloc set
      // `errorMessage` and nothing ever read it, so the student tapped and
      // simply nothing happened.
      listenWhen: (previous, current) =>
          current is CollectionReady && current.errorMessage != null,
      listener: (context, state) {
        final message = (state as CollectionReady).errorMessage;
        if (message == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      builder: (context, state) {
        if (state is CollectionLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is CollectionError) {
          return Scaffold(body: Center(child: Text(state.message)));
        }

        final ready = state as CollectionReady;
        final bloc = context.read<CollectionBloc>();
        final reveal = ready.pendingReveal;

        return Stack(
          children: [
            CollectionTemplate(
              quarkBalance: ready.quarkBalance,
              decks: ready.decks,
              selectedDeckId: ready.selectedDeckId,
              collection: ready.collection,
              deckErrorMessage: ready.deckErrorMessage,
              onSelectDeck: (deckId) => bloc.add(DeckSelected(deckId)),
              onCloseDeck: () => bloc.add(const DeckClosed()),
              onDraw: () => bloc.add(const DrawRequested()),
              onCardTap: (holding) => showDialog<void>(
                context: context,
                builder: (dialogContext) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: CardDetailOrganism(
                    params: CardDetailParams(
                      holding: holding,
                      onShatter: (variant) {
                        bloc.add(
                          ShatterCopyRequested(holding.card.id, variant),
                        );
                        Navigator.of(dialogContext).pop();
                      },
                      onClose: () => Navigator.of(dialogContext).pop(),
                    ),
                  ),
                ),
              ),
            ),
            if (reveal != null)
              Positioned.fill(
                child: CardRevealOrganism(
                  params: RevealParams(
                    outcome: reveal.outcome,
                    supportingLine: CollectionPresenter.revealSupportingLine(
                      outcome: reveal.outcome,
                      deckName: reveal.deckName,
                      collectionAfterDraw: reveal.collectionAfterDraw,
                    ),
                    onDismiss: () => bloc.add(const RevealDismissed()),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
