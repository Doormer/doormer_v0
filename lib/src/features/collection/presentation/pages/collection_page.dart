// lib/src/features/collection/presentation/pages/collection_page.dart
import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/responsive/margin_scrim_scope.dart';
import 'package:doormer/src/core/routes/app_router.dart';
import 'package:doormer/src/core/routes/shown_destination.dart';
import 'package:doormer/src/shared/design/atomic/molecules/error_with_retry_molecule.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
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
      child: Builder(
        // The page stays alive while the student is on other pages, where
        // solving earns quarks, so it reads the balance afresh on return.
        builder: (context) => DestinationListener(
          destination: AppDestination.cards,
          onReturnedTo: () => context
              .read<CollectionBloc>()
              .add(const CollectionRefreshRequested()),
          child: const _CollectionView(),
        ),
      ),
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
    final isShown =
        ShownDestination.maybeOf(context)?.destination ?? AppDestination.cards;

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
          return Scaffold(
            body: Center(
              child: ErrorWithRetryMolecule(
                message: state.message,
                onRetry: () => context
                    .read<CollectionBloc>()
                    .add(const CollectionStarted()),
              ),
            ),
          );
        }

        final ready = state as CollectionReady;
        final bloc = context.read<CollectionBloc>();
        final reveal =
            isShown == AppDestination.cards ? ready.pendingReveal : null;

        return _OnRootOverlay(
          // Over the whole screen, nav bar included, which belongs to the
          // shell around this page. Screen readers can't reach the bar
          // either.
          overlayChild: reveal == null
              ? null
              : Positioned.fill(
                  child: BlockSemantics(
                    child: MarginScrimScope(
                      tracker: AppRouter.popupRoutes,
                      barrierColor: CardRevealOrganism.barrierColor,
                      onDismiss: () => bloc.add(const RevealDismissed()),
                      child: CardRevealOrganism(
                        params: RevealParams(
                          outcome: reveal.outcome,
                          supportingLine:
                              CollectionPresenter.revealSupportingLine(
                            outcome: reveal.outcome,
                            deckName: reveal.deckName,
                            collectionAfterDraw: reveal.collectionAfterDraw,
                          ),
                          onDismiss: () => bloc.add(const RevealDismissed()),
                        ),
                      ),
                    ),
                  ),
                ),
          child: CollectionTemplate(
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
                          deckName: latest.collection?.deck.name ?? '',
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
          ),
        );
      },
    );
  }
}

/// Shows [overlayChild], when there is one, on the app's root overlay, above
/// everything [child] sits inside.
/// Shows [overlayChild], when there is one, in an entry of its own on the
/// root overlay, above the shell's nav bar. Unlike an `OverlayPortal`,
/// whose semantics stay where the portal sits, an entry's semantics come
/// after the bar's, so a [BlockSemantics] in it hides the bar too.
class _OnRootOverlay extends StatefulWidget {
  final Widget? overlayChild;
  final Widget child;

  const _OnRootOverlay({required this.overlayChild, required this.child});

  @override
  State<_OnRootOverlay> createState() => _OnRootOverlayState();
}

class _OnRootOverlayState extends State<_OnRootOverlay> {
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    _syncAfterFrame();
  }

  @override
  void didUpdateWidget(_OnRootOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.overlayChild != oldWidget.overlayChild) _syncAfterFrame();
  }

  // The overlay can't change while this page builds.
  void _syncAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final overlayChild = widget.overlayChild;
      if (overlayChild == null) {
        _removeEntry();
      } else if (_entry == null) {
        _entry = OverlayEntry(
          builder: (_) => widget.overlayChild ?? const SizedBox.shrink(),
        );
        Overlay.of(context, rootOverlay: true).insert(_entry!);
      } else {
        _entry!.markNeedsBuild();
      }
    });
  }

  void _removeEntry() {
    _entry
      ?..remove()
      ..dispose();
    _entry = null;
  }

  @override
  void dispose() {
    _removeEntry();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
