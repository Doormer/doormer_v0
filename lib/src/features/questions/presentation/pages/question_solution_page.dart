import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/friend_question_bloc.dart';
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
import 'package:doormer/src/shared/design/atomic/organisms/report_sheet_organism.dart';
import 'package:doormer/src/shared/design/atomic/params/report_sheet_params.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/widget/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

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
            final sharedBy = state.sharedBy;
            if (sharedBy != null) {
              return _friendQuestionReader(context, state, id, sharedBy);
            }
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

  /// A question [sharedBy] shared with the student, which they can remove
  /// or report.
  Widget _friendQuestionReader(
    BuildContext context,
    SolutionReaderReady state,
    String id,
    FriendSummary sharedBy,
  ) {
    return BlocProvider<FriendQuestionBloc>(
      create: (_) => serviceLocator<FriendQuestionBloc>()
        ..add(FriendQuestionStarted(questionId: id, sharedBy: sharedBy)),
      child: BlocConsumer<FriendQuestionBloc, FriendQuestionState>(
        listenWhen: (previous, current) =>
            current.errorMessage != null ||
            (current.exit != null && previous.exit == null),
        listener: _actOnFriendQuestion,
        builder: (context, friendQuestion) => _reader(
          context,
          state,
          share: FriendQuestionShareLineParams(
            sharedByLabel: sharedByLabel(sharedBy),
            nickname: sharedBy.nickname,
            artUrl: sharedBy.picture?.artUrl,
            isRemoving: friendQuestion.isRemoving,
            onRemove: () => _removeAfterAsking(context, sharedBy),
            onReport: () => _openReport(context, sharedBy),
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

  /// Says why an action failed, or, once the question has left the
  /// student's list, goes back to the tab it opened from.
  void _actOnFriendQuestion(
    BuildContext context,
    FriendQuestionState friendQuestion,
  ) {
    final error = friendQuestion.errorMessage;
    if (error != null) {
      CustomToast.show(context, message: error, type: ToastificationType.error);
      return;
    }
    if (friendQuestion.exit == FriendQuestionExit.removed) {
      CustomToast.show(context,
          message: 'Question removed.', type: ToastificationType.success);
    }
    // An answer can come as the reader closes because the student left it,
    // such as by Ask another question. The reader has then left the
    // navigator, and going to the tab would undo where they chose to go.
    if (!(ModalRoute.of(context)?.isActive ?? false)) return;
    context.go(tabLocation);
  }

  /// Asks before taking the question out of Shared with me. Only the friend
  /// can share it again.
  Future<void> _removeAfterAsking(
    BuildContext context,
    FriendSummary sharedBy,
  ) async {
    final bloc = context.read<FriendQuestionBloc>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove this question?',
      message: 'It leaves your Shared with me list. Only '
          '${sharedBy.nickname} can share it with you again.',
      confirmLabel: 'Remove',
      icon: Icons.remove_circle_outline_rounded,
    );
    if (confirmed) bloc.add(const SharedQuestionRemoved());
  }

  /// The report sheet for [sharedBy], with the question attached. It sits on
  /// the root navigator, outside this page's providers, so the bloc is
  /// handed in.
  ///
  /// Block shows only once the report is sent: a block ends the share, and a
  /// report about a share that has ended is refused.
  void _openReport(BuildContext context, FriendSummary sharedBy) {
    final bloc = context.read<FriendQuestionBloc>()
      ..add(const SharedQuestionReportOpened());
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) =>
          BlocBuilder<FriendQuestionBloc, FriendQuestionState>(
        bloc: bloc,
        builder: (_, friendQuestion) {
          final status = friendQuestion.reportStatus;
          return ReportSheetOrganism(
            params: ReportSheetParams(
              title: 'Report ${sharedBy.nickname}',
              isSending: status == QuestionReportStatus.sending,
              isSent: status == QuestionReportStatus.sent,
              onSend: (reason, note) => bloc.add(
                SharedQuestionReported(reason: reason, note: note),
              ),
              onBlock: status == QuestionReportStatus.sent
                  ? () => _blockAfterAsking(sheetContext, bloc, sharedBy)
                  : null,
              onClose: () => Navigator.of(sheetContext).pop(),
              onOpenLink: (link) =>
                  launchUrl(link, webOnlyWindowName: '_blank'),
            ),
          );
        },
      ),
    );
  }

  /// Asks before blocking [sharedBy], in Profile's words, then closes the
  /// report sheet. Blocking also ends this share, so the reader closes too.
  Future<void> _blockAfterAsking(
    BuildContext sheetContext,
    FriendQuestionBloc bloc,
    FriendSummary sharedBy,
  ) async {
    final confirmed = await showConfirmDialog(
      sheetContext,
      title: 'Block ${sharedBy.nickname}?',
      message: "They won't see your cards or anything you shared, and their "
          "requests won't reach you. They won't be told.",
      confirmLabel: 'Block',
      icon: Icons.block_rounded,
    );
    if (!confirmed) return;
    bloc.add(const FriendBlocked());
    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
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
