import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/routes/shown_destination.dart';
import 'package:doormer/src/features/questions/domain/entity/shared_question_summary.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_question_summary.dart';
import 'package:doormer/src/features/questions/presentation/bloc/saved_questions_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/shared_questions_bloc.dart';
import 'package:doormer/src/features/questions/presentation/mapper/saved_question_row_presenter.dart';
import 'package:doormer/src/features/questions/presentation/organisms/enlarge_sheet_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/photo_enlarge_organism.dart';
import 'package:doormer/src/features/questions/presentation/pages/ask_by_photo_page.dart';
import 'package:doormer/src/features/questions/presentation/params/saved_list_switch_params.dart';
import 'package:doormer/src/features/questions/presentation/params/saved_question_row_params.dart';
import 'package:doormer/src/features/questions/presentation/params/saved_questions_body_params.dart';
import 'package:doormer/src/features/questions/presentation/templates/saved_questions_template.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The Saved tab: the student's solved questions, newest first, and the
/// questions friends shared with them, newest share first. The only widget
/// on this screen that touches flutter_bloc.
class SavedQuestionsPage extends StatelessWidget {
  /// The clock "when asked" and "when shared" are measured against. Tests fix
  /// it.
  final DateTime Function() now;

  /// Whether a solution opened from Saved covers it. When it closes, Shared
  /// with me is read again, quietly: the student may have removed the
  /// question there, or blocked the friend who shared it.
  final bool isCovered;

  const SavedQuestionsPage({
    super.key,
    this.now = DateTime.now,
    this.isCovered = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SavedQuestionsBloc>(
          create: (_) => serviceLocator<SavedQuestionsBloc>()
            ..add(const SavedQuestionsStarted()),
        ),
        // Made, and loaded, the first time the student opens Shared with me.
        BlocProvider<SharedQuestionsBloc>(
          create: (_) => serviceLocator<SharedQuestionsBloc>()
            ..add(const SharedQuestionsStarted()),
        ),
      ],
      child: _SavedQuestionsView(now: now, isCovered: isCovered),
    );
  }
}

class _SavedQuestionsView extends StatefulWidget {
  final DateTime Function() now;
  final bool isCovered;

  const _SavedQuestionsView({required this.now, required this.isCovered});

  @override
  State<_SavedQuestionsView> createState() => _SavedQuestionsViewState();
}

class _SavedQuestionsViewState extends State<_SavedQuestionsView> {
  SavedList _list = SavedList.mine;

  /// Shared with me has been opened, so it is loaded and kept up to date.
  bool _sharedOpened = false;

  @override
  void didUpdateWidget(_SavedQuestionsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCovered && !widget.isCovered) _refreshShared();
  }

  void _refreshShared() {
    if (!_sharedOpened) return;
    context
        .read<SharedQuestionsBloc>()
        .add(const SharedQuestionsRefreshRequested());
  }

  void _select(SavedList list) {
    if (list == _list) return;
    // Opened again, Shared with me reads what has changed since.
    if (list == SavedList.sharedWithMe) _refreshShared();
    setState(() {
      _list = list;
      if (list == SavedList.sharedWithMe) _sharedOpened = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // The page stays alive while the student is on other pages, where they
    // may solve a question, or a friend may share one, so it checks on
    // return.
    return DestinationListener(
      destination: AppDestination.saved,
      onReturnedTo: () {
        context
            .read<SavedQuestionsBloc>()
            .add(const SavedQuestionsRefreshRequested());
        _refreshShared();
      },
      child: switch (_list) {
        SavedList.mine => BlocBuilder<SavedQuestionsBloc, SavedQuestionsState>(
            builder: (context, state) => _template(_mineBody(context, state)),
          ),
        SavedList.sharedWithMe =>
          BlocBuilder<SharedQuestionsBloc, SharedQuestionsState>(
            builder: (context, state) => _template(_sharedBody(context, state)),
          ),
      },
    );
  }

  Widget _template(SavedQuestionsBodyParams body) => SavedQuestionsTemplate(
        listSwitch: SavedListSwitchParams(selected: _list, onSelect: _select),
        body: body,
      );

  SavedQuestionsBodyParams _mineBody(
    BuildContext context,
    SavedQuestionsState state,
  ) {
    final bloc = context.read<SavedQuestionsBloc>();
    return switch (state) {
      SavedQuestionsLoading() => const SavedQuestionsLoadingParams(),
      SavedQuestionsEmpty() => SavedQuestionsEmptyParams(
          onSolve: () => context.go(
            '/questions/photo',
            extra: ShowPhotoSourceOptionsOnOpen(),
          ),
        ),
      SavedQuestionsError(:final message) => SavedQuestionsErrorParams(
          message: message,
          onRetry: () => bloc.add(const SavedQuestionsRetried()),
        ),
      SavedQuestionsReady ready => SavedQuestionListParams(
          rows: [
            for (final question in ready.questions) _rowFor(context, question),
          ],
          hasMore: ready.hasMore,
          isLoadingMore: ready.isLoadingMore,
          loadMoreFailed: ready.loadMoreFailed,
          onLoadMore: () => bloc.add(const SavedQuestionsMoreRequested()),
          onRetryLoadMore: () => bloc.add(const SavedQuestionsRetried()),
        ),
    };
  }

  SavedQuestionsBodyParams _sharedBody(
    BuildContext context,
    SharedQuestionsState state,
  ) {
    final bloc = context.read<SharedQuestionsBloc>();
    return switch (state) {
      SharedQuestionsLoading() => const SavedQuestionsLoadingParams(),
      SharedQuestionsEmpty() => const SharedQuestionsEmptyParams(),
      SharedQuestionsError(:final message) => SavedQuestionsErrorParams(
          message: message,
          onRetry: () => bloc.add(const SharedQuestionsRetried()),
        ),
      SharedQuestionsReady ready => SavedQuestionListParams(
          rows: [
            for (final shared in ready.questions)
              _sharedRowFor(context, shared),
          ],
          hasMore: ready.hasMore,
          isLoadingMore: ready.isLoadingMore,
          loadMoreFailed: ready.loadMoreFailed,
          onLoadMore: () => bloc.add(const SharedQuestionsMoreRequested()),
          onRetryLoadMore: () => bloc.add(const SharedQuestionsRetried()),
        ),
    };
  }

  SavedQuestionRowParams _rowFor(
    BuildContext context,
    SolvedQuestionSummary question,
  ) {
    final content = savedQuestionRowContent(question, now: widget.now());
    return SavedQuestionRowParams(
      title: content.title,
      detail: content.detail,
      dayLabel: content.askedLabel,
      thumbnailUrl: question.thumbnailUrl,
      onOpen: () => _openSolution(context, question.questionId),
      onEnlargePhoto: () => _openPhoto(context, question.photoUrl),
    );
  }

  SavedQuestionRowParams _sharedRowFor(
    BuildContext context,
    SharedQuestionSummary shared,
  ) {
    final content = sharedQuestionRowContent(shared, now: widget.now());
    final question = shared.question;
    return SavedQuestionRowParams(
      title: content.title,
      detail: content.detail,
      dayLabel: content.sharedLabel,
      thumbnailUrl: question.thumbnailUrl,
      sender: (
        nickname: shared.sharedBy.nickname,
        artUrl: shared.sharedBy.picture?.artUrl,
      ),
      onOpen: () => _openSolution(context, question.questionId),
      onEnlargePhoto: () => _openPhoto(context, question.photoUrl),
    );
  }

  /// `go` to the solution's own address, under Saved: it opens over the nav
  /// bar with this page kept under it, so back shows the list as it was
  /// left, and a refresh keeps the solution. A question a friend shared
  /// opens there too.
  void _openSolution(BuildContext context, String questionId) =>
      context.go('/saved/${Uri.encodeComponent(questionId)}/solution');

  void _openPhoto(BuildContext context, String? photoUrl) {
    // Over the nav bar, which belongs to the shell.
    Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder<void>(
        // The sheet paints its own opaque backdrop as it fades in, so the
        // list must stay painted underneath it.
        opaque: false,
        barrierDismissible: false,
        transitionDuration: EnlargeSheetOrganism.cardRise,
        pageBuilder: (routeContext, _, __) => PhotoEnlargeOrganism(
          photoUrl: photoUrl,
          onClose: () => Navigator.of(routeContext).pop(),
        ),
      ),
    );
  }
}
