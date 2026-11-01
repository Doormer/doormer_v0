import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/friends/friends_messages.dart';
import 'package:doormer/src/shared/levels/level_labels.dart';
import 'package:doormer/src/shared/widget/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

import '../../domain/entity/holding.dart';
import '../bloc/friend_collection_bloc.dart';
import '../mapper/collection_presenter.dart';
import '../organisms/card_detail_organism.dart';
import '../params/card_detail_params.dart';
import '../params/friend_collection_body_params.dart';
import '../templates/friend_collection_template.dart';

/// A friend's collection, at `/profile/friends/:friendId/cards`, inside the
/// Profile tab. The only widget on this screen that touches flutter_bloc.
class FriendCollectionPage extends StatelessWidget {
  final String friendId;

  /// The friend as Profile showed them, so the heading shows at once. Null
  /// when the collection was opened by its address.
  final FriendSummary? friend;

  const FriendCollectionPage({super.key, required this.friendId, this.friend});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FriendCollectionBloc>(
      create: (_) => serviceLocator<FriendCollectionBloc>()
        ..add(FriendCollectionStarted(friendId: friendId, friend: friend)),
      child: BlocConsumer<FriendCollectionBloc, FriendCollectionState>(
        listenWhen: (_, current) => current is FriendCollectionGone,
        listener: (context, _) {
          CustomToast.show(
            context,
            message: FriendsMessages.friendNotFound,
            type: ToastificationType.error,
          );
          context.go('/profile');
        },
        builder: (context, state) {
          final shown = _friendIn(state);
          final level = shown?.level;
          return FriendCollectionTemplate(
            title: CollectionPresenter.friendCardsTitle(shown?.nickname),
            nickname: shown?.nickname,
            artUrl: shown?.picture?.artUrl,
            level: level,
            levelLabel: level == null ? null : LevelLabels.levelOf(level),
            body: _bodyFor(context, state),
            onBack: () => context.go('/profile'),
          );
        },
      ),
    );
  }

  FriendSummary? _friendIn(FriendCollectionState state) => switch (state) {
        FriendCollectionLoading(:final friend) => friend,
        FriendCollectionError(:final friend) => friend,
        FriendCollectionReady(:final friend) => friend,
        FriendCollectionGone() => friend,
      };

  FriendCollectionBodyParams _bodyFor(
    BuildContext context,
    FriendCollectionState state,
  ) {
    final bloc = context.read<FriendCollectionBloc>();
    return switch (state) {
      FriendCollectionLoading() ||
      FriendCollectionGone() =>
        const FriendCollectionLoadingParams(),
      FriendCollectionError(:final message) => FriendCollectionErrorParams(
          message: message,
          onRetry: () => bloc.add(
            FriendCollectionStarted(friendId: friendId, friend: friend),
          ),
        ),
      FriendCollectionReady(selectedDeckId: null) && final ready =>
        FriendDeckListParams(
          decks: CollectionPresenter.friendDeckRows(
            decks: ready.decks,
            onSelect: (deckId) => bloc.add(FriendDeckSelected(deckId)),
          ),
        ),
      FriendCollectionReady ready => _deckParams(context, ready),
    };
  }

  FriendDeckParams _deckParams(
    BuildContext context,
    FriendCollectionReady ready,
  ) {
    final bloc = context.read<FriendCollectionBloc>();
    final deckId = ready.selectedDeckId!;
    final collection = ready.collection;
    final deckName = collection?.deck.name ??
        ready.decks.firstWhere((deck) => deck.deckId == deckId).name;
    return FriendDeckParams(
      deckName: deckName,
      heldLabel:
          collection == null ? null : CollectionPresenter.heldLabel(collection),
      holdings: collection?.holdings ?? const [],
      isLoading: collection == null && ready.deckErrorMessage == null,
      errorMessage: ready.deckErrorMessage,
      onRetry: () => bloc.add(FriendDeckSelected(deckId)),
      onClose: () => bloc.add(const FriendDeckClosed()),
      onCardTap: (holding) => _openCard(context, holding, deckName),
    );
  }

  /// The card's detail, with no quarks and no Shatter: the cards are the
  /// friend's.
  void _openCard(BuildContext context, Holding holding, String deckName) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: CardDetailOrganism(
          params: CardDetailParams(
            holding: holding,
            deckName: deckName,
            onClose: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      ),
    );
  }
}
