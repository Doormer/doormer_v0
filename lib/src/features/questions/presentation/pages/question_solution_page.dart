import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/share_question_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/solution_reader_bloc.dart';
import 'package:doormer/src/features/questions/presentation/mapper/question_sharing_presenter.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_reader_presenter.dart';
import 'package:doormer/src/features/questions/presentation/organisms/diagram_enlarge_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/share_question_sheet_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/share_question_sheet_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_reader_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_share_line_params.dart';
import 'package:doormer/src/features/questions/presentation/templates/solution_reader_placeholder_template.dart';
import 'package:doormer/src/features/questions/presentation/templates/solution_reader_template.dart';
import 'package:doormer/src/shared/design/atomic/molecules/confirm_dialog_molecule.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/widget/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

/// The only layer that touches flutter_bloc.
class QuestionSolutionPage extends StatelessWidget {
  final String? questionId;
  final AskByPhotoSolved? solvedState;

  /// The address of the tab this solution opened over. Back on the "couldn't
  /// load" screen goes there.
  final String tabLocation;

  /// That tab's name, as the nav bar shows it.
  final String tabName;

  const QuestionSolutionPage({
    super.key,
    this.questionId,
    this.solvedState,
    this.tabLocation = '/questions/photo',
    this.tabName = 'Solve',
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SolutionReaderBloc>(
      create: (_) => serviceLocator<SolutionReaderBloc>()
        ..add(SolutionReaderStarted(
          document: solvedState?.solution,
          note: solvedState?.note ?? '',
          topic: solvedState?.topic ?? '',
          method: solvedState?.method ?? '',
          questionId: questionId,
        )),
      child: BlocBuilder<SolutionReaderBloc, SolutionReaderState>(
        builder: (context, state) {
          if (state is SolutionReaderReady) {
            final id = questionId;
            // The sample can't be shared.
            if (id == null) return _reader(context, state);
            return _ownQuestionReader(context, state, id);
          }

          if (state is SolutionReaderError) {
            return SolutionReaderPlaceholderTemplate(
              message: state.message,
              onBack: () => context.go(tabLocation),
              backLabel: 'Back to $tabName',
            );
          }

          return const SolutionReaderPlaceholderTemplate();
        },
      ),
    );
  }

  /// The student's own question, which they can share. The sharing bloc
  /// starts with whoever the question was shared with as it opened.
  Widget _ownQuestionReader(
    BuildContext context,
    SolutionReaderReady state,
    String id,
  ) {
    return BlocProvider<ShareQuestionBloc>(
      create: (_) => serviceLocator<ShareQuestionBloc>()
        ..add(
            ShareQuestionStarted(questionId: id, sharedWith: state.sharedWith)),
      child: BlocConsumer<ShareQuestionBloc, ShareQuestionState>(
        listenWhen: (_, current) =>
            current.notice != null || current.errorMessage != null,
        listener: _sayHowSharingWent,
        builder: (context, sharing) => _reader(
          context,
          state,
          share: OwnQuestionShareLineParams(
            sharedWithLabel: sharedWithLabel(sharing.sharedWith),
            isStopping: sharing.isStopping,
            onShare: () => _openShareSheet(context),
            onStopSharing: () => _stopSharingAfterAsking(context),
          ),
        ),
      ),
    );
  }

  Widget _reader(
    BuildContext context,
    SolutionReaderReady state, {
    SolutionShareLineParams? share,
  }) {
    final bloc = context.read<SolutionReaderBloc>();
    final content = solutionReaderContent(state);
    return SolutionReaderTemplate(
      params: SolutionReaderParams(
        content: content,
        onNext: () => content.answerRevealed
            ? context.go('/questions/photo')
            : bloc.add(const SolutionReaderAdvanced()),
        onBack: () => bloc.add(const SolutionReaderWentBack()),
        onToggleRationale: () =>
            bloc.add(const SolutionReaderRationaleToggled()),
        onRevealAnswer: () => bloc.add(SolutionReaderAnswerRevealed(
          questionId: questionId,
        )),
        onTravelTo: (position) => bloc.add(SolutionReaderTravelled(position)),
        onEnlargeVisual: (visual) => _openEnlarge(context, visual),
        share: share,
      ),
    );
  }

  void _sayHowSharingWent(BuildContext context, ShareQuestionState sharing) {
    final error = sharing.errorMessage;
    if (error != null) {
      CustomToast.show(context, message: error, type: ToastificationType.error);
      return;
    }
    CustomToast.show(
      context,
      message: switch (sharing.notice!) {
        ShareNotice.shared => 'Question shared.',
        ShareNotice.stopped => 'Stopped sharing.',
      },
      type: ToastificationType.success,
    );
  }

  /// The sheet of friends, over the whole screen. It sits on the root
  /// navigator, outside this page's providers, so the bloc is handed in. It
  /// closes itself once the question is shared.
  void _openShareSheet(BuildContext context) {
    final bloc = context.read<ShareQuestionBloc>()
      ..add(const ShareSheetOpened());
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) =>
          BlocConsumer<ShareQuestionBloc, ShareQuestionState>(
        bloc: bloc,
        listenWhen: (_, current) => current.notice == ShareNotice.shared,
        listener: (_, __) {
          // A share can answer as the sheet closes. The sheet has then left
          // the top of the navigator, and a pop would close the reader.
          if (ModalRoute.of(sheetContext)?.isCurrent ?? false) {
            Navigator.of(sheetContext).pop();
          }
        },
        // Once sent, the sheet keeps its friends on screen as it closes.
        buildWhen: (_, current) => current.sheet is! ShareSheetClosed,
        builder: (_, sharing) => ShareQuestionSheetOrganism(
          params: ShareQuestionSheetParams(
            body: _sheetBody(bloc, sharing),
            onClose: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      ),
    );
  }

  ShareSheetBodyParams _sheetBody(
    ShareQuestionBloc bloc,
    ShareQuestionState sharing,
  ) {
    return switch (sharing.sheet) {
      ShareSheetClosed() ||
      ShareSheetLoading() =>
        const ShareSheetLoadingParams(),
      ShareSheetUnavailable(:final message) =>
        ShareSheetMessageParams(message: message),
      ShareSheetError(:final message) => ShareSheetMessageParams(
          message: message,
          onRetry: () => bloc.add(const ShareSheetOpened()),
        ),
      ShareSheetReady ready => ShareSheetFriendsParams(
          friends: [
            for (final friend in ready.friends)
              _friendRow(bloc, sharing, ready, friend),
          ],
          isFull: ready.isFull,
          isSending: ready.isSending,
          onSend: ready.ticked.isEmpty || ready.isSending
              ? null
              : () => bloc.add(const ShareSent()),
        ),
    };
  }

  /// A friend the question is already shared with stays ticked. Once the
  /// sheet is full, only a ticked friend can change.
  ShareFriendRowParams _friendRow(
    ShareQuestionBloc bloc,
    ShareQuestionState sharing,
    ShareSheetReady ready,
    FriendSummary friend,
  ) {
    final isShared = sharing.isSharedWith(friend.friendId);
    final isTicked = isShared || ready.ticked.contains(friend.friendId);
    final canToggle =
        !isShared && !ready.isSending && (isTicked || !ready.isFull);
    return ShareFriendRowParams(
      nickname: friend.nickname,
      artUrl: friend.picture?.artUrl,
      isTicked: isTicked,
      isShared: isShared,
      onToggle: canToggle
          ? () => bloc.add(ShareFriendToggled(friend.friendId))
          : null,
    );
  }

  /// Asks before taking the question out of every friend's list. Only
  /// sharing again brings it back.
  Future<void> _stopSharingAfterAsking(BuildContext context) async {
    final bloc = context.read<ShareQuestionBloc>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Stop sharing?',
      message: "Your friends won't see this question any more.",
      confirmLabel: 'Stop sharing',
      icon: Icons.link_off_rounded,
    );
    if (confirmed) bloc.add(const SharingStopped());
  }

  void _openEnlarge(BuildContext context, VisualSolutionSegment visual) {
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        // The sheet paints its own opaque backdrop as it fades in, so the
        // route below must stay painted underneath — an opaque route would be
        // swapped in whole and there would be nothing to fade over.
        opaque: false,
        barrierDismissible: false,
        transitionDuration: DiagramEnlargeOrganism.cardRise,
        pageBuilder: (routeContext, _, __) => DiagramEnlargeOrganism(
          visual: visual,
          onClose: () => Navigator.of(routeContext).pop(),
        ),
      ),
    );
  }
}
