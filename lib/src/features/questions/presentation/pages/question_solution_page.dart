import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/solution_reader_bloc.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_reader_presenter.dart';
import 'package:doormer/src/features/questions/presentation/organisms/diagram_enlarge_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_reader_params.dart';
import 'package:doormer/src/features/questions/presentation/templates/solution_reader_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The only layer that touches flutter_bloc.
class QuestionSolutionPage extends StatelessWidget {
  final String questionId;
  final AskByPhotoSolved? solvedState;

  const QuestionSolutionPage({
    super.key,
    required this.questionId,
    this.solvedState,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SolutionReaderBloc>(
      create: (_) => serviceLocator<SolutionReaderBloc>()
        ..add(SolutionReaderStarted(
          document: solvedState?.solution,
          note: solvedState?.note ?? '',
        )),
      child: BlocBuilder<SolutionReaderBloc, SolutionReaderState>(
        builder: (context, state) {
          if (state is SolutionReaderReady) {
            final bloc = context.read<SolutionReaderBloc>();
            return SolutionReaderTemplate(
              params: SolutionReaderParams(
                content: solutionReaderContent(state),
                onNext: () => bloc.add(const SolutionReaderAdvanced()),
                onBack: () => bloc.add(const SolutionReaderWentBack()),
                onToggleRationale: () =>
                    bloc.add(const SolutionReaderRationaleToggled()),
                onRevealAnswer: () =>
                    bloc.add(const SolutionReaderAnswerRevealed()),
                onEnlargeVisual: (visual) => _openEnlarge(context, visual),
              ),
            );
          }

          if (state is SolutionReaderError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyLarge,
                  ),
                ),
              ),
            );
          }

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  void _openEnlarge(BuildContext context, VisualSolutionSegment visual) {
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        barrierDismissible: false,
        pageBuilder: (routeContext, _, __) => DiagramEnlargeOrganism(
          visual: visual,
          onClose: () => Navigator.of(routeContext).pop(),
        ),
      ),
    );
  }
}
