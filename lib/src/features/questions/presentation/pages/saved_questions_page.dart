import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_question_summary.dart';
import 'package:doormer/src/features/questions/presentation/bloc/saved_questions_bloc.dart';
import 'package:doormer/src/features/questions/presentation/mapper/saved_question_row_presenter.dart';
import 'package:doormer/src/features/questions/presentation/organisms/enlarge_sheet_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/photo_enlarge_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/saved_question_row_params.dart';
import 'package:doormer/src/features/questions/presentation/params/saved_questions_body_params.dart';
import 'package:doormer/src/features/questions/presentation/templates/saved_questions_template.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:doormer/src/shared/widget/coming_soon_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The Saved tab: the student's solved questions, newest first. The only
/// widget on this screen that touches flutter_bloc.
class SavedQuestionsPage extends StatelessWidget {
  /// The clock "when asked" is measured against. Tests fix it.
  final DateTime Function() now;

  const SavedQuestionsPage({super.key, this.now = DateTime.now});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SavedQuestionsBloc>(
      create: (_) => serviceLocator<SavedQuestionsBloc>()
        ..add(const SavedQuestionsStarted()),
      child: BlocBuilder<SavedQuestionsBloc, SavedQuestionsState>(
        builder: (context, state) => SavedQuestionsTemplate(
          body: _bodyFor(context, state),
          navigationBarParams: NavigationBarParams(
            current: AppDestination.saved,
            // Already here.
            onSaved: () {},
            onAiTutor: () => showComingSoon(context),
            onSolve: () => context.go('/questions/photo'),
            onCards: () => context.go('/collection'),
            onProfile: () => context.go('/profile'),
          ),
        ),
      ),
    );
  }

  SavedQuestionsBodyParams _bodyFor(
    BuildContext context,
    SavedQuestionsState state,
  ) {
    final bloc = context.read<SavedQuestionsBloc>();
    return switch (state) {
      SavedQuestionsLoading() => const SavedQuestionsLoadingParams(),
      SavedQuestionsEmpty() => SavedQuestionsEmptyParams(
          onSolve: () => context.go('/questions/photo'),
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

  SavedQuestionRowParams _rowFor(
    BuildContext context,
    SolvedQuestionSummary question,
  ) {
    final content = savedQuestionRowContent(question, now: now());
    return SavedQuestionRowParams(
      title: content.title,
      detail: content.detail,
      askedLabel: content.askedLabel,
      thumbnailUrl: question.thumbnailUrl,
      // `go`, as Solve does, so the address is the solution's own: back
      // returns here and a refresh keeps the solution.
      onOpen: () => context.go(
          '/questions/${Uri.encodeComponent(question.questionId)}/solution'),
      onEnlargePhoto: () => _openPhoto(context, question.photoUrl),
    );
  }

  void _openPhoto(BuildContext context, String? photoUrl) {
    Navigator.of(context).push<void>(
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
