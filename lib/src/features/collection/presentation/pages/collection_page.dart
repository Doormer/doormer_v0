// lib/src/features/collection/presentation/pages/collection_page.dart
import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:doormer/src/shared/widget/coming_soon_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/collection_bloc.dart';
import '../molecules/error_with_retry_molecule.dart';
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

class _CollectionView extends StatefulWidget {
  const _CollectionView();

  @override
  State<_CollectionView> createState() => _CollectionViewState();
}

class _CollectionViewState extends State<_CollectionView> {
  /// On the open deck balance's quark dot. A card window aims a shatter's
  /// quark dots there.
  final _quarkDotKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // One set for all three screens: loading, error and ready.
    final navigationBarParams = NavigationBarParams(
      current: AppDestination.cards,
      onSaved: () => showComingSoon(context),
      onAiTutor: () => showComingSoon(context),
      onSolve: () => context.go('/questions/photo'),
      // Already here.
      onCards: () {},
      onProfile: () => context.go('/profile'),
    );

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
          return Scaffold(
            backgroundColor: CollectionTemplate.background,
            body: const Center(child: CircularProgressIndicator()),
            bottomNavigationBar:
                CollectionTemplate.navigationBar(navigationBarParams),
          );
        }
        if (state is CollectionError) {
          return Scaffold(
            backgroundColor: CollectionTemplate.background,
            body: Center(
              child: ErrorWithRetryMolecule(
                message: state.message,
                onRetry: () => context
                    .read<CollectionBloc>()
                    .add(const CollectionStarted()),
              ),
            ),
            bottomNavigationBar:
                CollectionTemplate.navigationBar(navigationBarParams),
          );
        }

        final ready = state as CollectionReady;
        final bloc = context.read<CollectionBloc>();
        final reveal = ready.pendingReveal;

        return Stack(
          children: [
            CollectionTemplate(
              quarkBalance: ready.quarkBalance,
              quarkDotKey: _quarkDotKey,
              decks: ready.decks,
              selectedDeckId: ready.selectedDeckId,
              collection: ready.collection,
              deckErrorMessage: ready.deckErrorMessage,
              isDrawing: ready.isDrawing,
              onSelectDeck: (deckId) => bloc.add(DeckSelected(deckId)),
              onCloseDeck: () => bloc.add(const DeckClosed()),
              onDraw: () => bloc.add(const DrawRequested()),
              onCardTap: (tapped) {
                // An error already in the state when the window opens is
                // about something else: a draw, or a shatter in a window since
                // closed. The window only says why its own shatters failed.
                final stateWhenOpened = bloc.state;
                showDialog<void>(
                  context: context,
                  builder: (dialogContext) => Dialog(
                    backgroundColor: Colors.transparent,
                    // The window stays open and rebuilds as copies are
                    // shattered. It sits on the root navigator, outside this
                    // page's BlocProvider, so the bloc is handed in.
                    child: BlocBuilder<CollectionBloc, CollectionState>(
                      bloc: bloc,
                      buildWhen: (_, current) => current is CollectionReady,
                      builder: (context, state) {
                        final latest = state as CollectionReady;
                        return CardDetailOrganism(
                          params: CardDetailParams(
                            holding:
                                latest.collection?.holdingOf(tapped.card.id) ??
                                    tapped,
                            quarkBalance: latest.quarkBalance,
                            quarkDotKey: _quarkDotKey,
                            isShattering: latest.isShattering,
                            errorMessage: identical(latest, stateWhenOpened)
                                ? null
                                : latest.errorMessage,
                            onShatter: (variant) => bloc.add(
                              ShatterCopyRequested(tapped.card.id, variant),
                            ),
                            onClose: () => Navigator.of(dialogContext).pop(),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              navigationBarParams: navigationBarParams,
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
