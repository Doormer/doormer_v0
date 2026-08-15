import 'package:doormer/src/features/questions/presentation/bloc/solution_reader_bloc.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_segment_order.dart';
import 'package:doormer/src/features/questions/presentation/molecules/solution_trail_molecule.dart';

/// Everything the widget tree needs to draw one frame of the reader.
class SolutionReaderContent {
  final String levelLabel;
  final String stepTitle;
  final List<OrderedSegment> body;
  final List<OrderedSegment> rationale;
  final bool hasRationale;
  final bool rationaleVisible;
  final String rationaleToggleLabel;
  final List<SolutionTrailNode> trail;
  final bool answerRevealed;
  final List<OrderedSegment> answerBody;
  final String vaultLockedLabel;
  final String ctaLabel;
  final bool ctaEnabled;
  final bool canGoBack;
  final bool isLastStep;

  const SolutionReaderContent({
    required this.levelLabel,
    required this.stepTitle,
    required this.body,
    required this.rationale,
    required this.hasRationale,
    required this.rationaleVisible,
    required this.rationaleToggleLabel,
    required this.trail,
    required this.answerRevealed,
    required this.answerBody,
    required this.vaultLockedLabel,
    required this.ctaLabel,
    required this.ctaEnabled,
    required this.canGoBack,
    required this.isLastStep,
  });
}

/// Turns reader state into display copy. Page-invoked only — nothing below the
/// page calls this, and nothing below the page sees bloc state.
///
/// The level label deliberately carries no total: the node trail is the page's
/// only progress indicator.
SolutionReaderContent solutionReaderContent(SolutionReaderReady state) {
  final steps = state.document.steps;
  final step = steps[state.stepIndex];
  final stepCount = steps.length;

  // Gate: answerRevealed stays true after a reveal-then-back, but it must only
  // take effect on the last step. On any earlier step the vault stays locked
  // and the CTA stays enabled.
  final bool answerRevealed = state.isLastStep && state.answerRevealed;

  return SolutionReaderContent(
    levelLabel: 'LEVEL ${state.stepIndex + 1}',
    stepTitle: step.title,
    body: diagramFirstOrder(step.body),
    rationale: diagramFirstOrder(step.rationale),
    hasRationale: step.rationale.isNotEmpty,
    rationaleVisible: state.rationaleVisible,
    rationaleToggleLabel: 'Why this works',
    trail: [
      for (var i = 0; i < stepCount; i++)
        SolutionTrailNode(
          displayNumber: i + 1,
          state: i < state.stepIndex
              ? SolutionTrailNodeState.done
              : i == state.stepIndex
                  ? SolutionTrailNodeState.current
                  : SolutionTrailNodeState.upcoming,
          semanticsLabel: 'Step ${i + 1}: ${steps[i].title}',
        ),
    ],
    answerRevealed: answerRevealed,
    answerBody: diagramFirstOrder(state.document.finalAnswer.body),
    vaultLockedLabel: state.isLastStep
        ? 'Tap to crack it open'
        : 'Answer unlocks after step $stepCount',
    ctaLabel: answerRevealed
        ? 'Solved'
        : state.isLastStep
            ? 'Reveal answer'
            : 'Next step',
    ctaEnabled: !answerRevealed,
    canGoBack: !state.isFirstStep,
    isLastStep: state.isLastStep,
  );
}
