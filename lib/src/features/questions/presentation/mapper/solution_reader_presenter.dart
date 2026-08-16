import 'package:doormer/src/features/questions/presentation/bloc/solution_reader_bloc.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_segment_order.dart';
import 'package:doormer/src/features/questions/presentation/molecules/solution_trail_molecule.dart';
import 'package:flutter/material.dart' show Icons;

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

  /// True while the orientation screen is showing, before step one.
  final bool onBriefing;
  final String briefingTitle;
  final List<OrderedSegment> briefingBody;

  /// Solver caveat shown on the briefing. Empty when there is none.
  final String note;

  final String checkTitle;

  /// Empty until the answer is revealed — a check read before the answer is
  /// just another step.
  final List<OrderedSegment> checkBody;

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
    required this.onBriefing,
    required this.briefingTitle,
    required this.briefingBody,
    required this.note,
    required this.checkTitle,
    required this.checkBody,
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
  final hasBriefing = state.hasBriefing;
  final onBriefing = state.onBriefing;

  // On the briefing the student is not on any step. Reporting isLastStep there
  // would let the CTA reveal the answer of a one-step solution before a single
  // step had been read, so every isLastStep consumer sees false instead.
  final bool isLastStep = !onBriefing && state.isLastStep;

  // Gate: answerRevealed stays true after a reveal-then-back, but it must only
  // take effect on the last step. On any earlier step the vault stays locked
  // and the CTA stays enabled.
  final bool answerRevealed = isLastStep && state.answerRevealed;

  return SolutionReaderContent(
    levelLabel: 'LEVEL ${state.stepIndex + 1}',
    stepTitle: step.title,
    body: diagramFirstOrder(step.body),
    rationale: diagramFirstOrder(step.rationale),
    hasRationale: step.rationale.isNotEmpty,
    rationaleVisible: state.rationaleVisible,
    rationaleToggleLabel: 'Why this works',
    trail: [
      if (hasBriefing)
        SolutionTrailNode(
          displayNumber: 0,
          state: onBriefing
              ? SolutionTrailNodeState.current
              : SolutionTrailNodeState.done,
          semanticsLabel: 'The plan',
          icon: Icons.flag_outlined,
        ),
      for (var i = 0; i < stepCount; i++)
        SolutionTrailNode(
          displayNumber: i + 1,
          state: onBriefing || i > state.stepIndex
              ? SolutionTrailNodeState.upcoming
              : i < state.stepIndex
                  ? SolutionTrailNodeState.done
                  : SolutionTrailNodeState.current,
          semanticsLabel: 'Step ${i + 1}: ${steps[i].title}',
        ),
    ],
    answerRevealed: answerRevealed,
    answerBody: diagramFirstOrder(state.document.finalAnswer.body),
    vaultLockedLabel: isLastStep
        ? 'Tap to crack it open'
        : 'Answer unlocks after step $stepCount',
    ctaLabel: onBriefing
        ? 'Start solving'
        : answerRevealed
            ? 'Solved'
            : isLastStep
                ? 'Reveal answer'
                : 'Next step',
    ctaEnabled: !answerRevealed,
    canGoBack: onBriefing ? false : (!state.isFirstStep || hasBriefing),
    isLastStep: isLastStep,
    onBriefing: onBriefing,
    briefingTitle: 'The plan',
    briefingBody: diagramFirstOrder(state.document.approach.body),
    note: state.note,
    checkTitle: 'Check it',
    checkBody: answerRevealed
        ? diagramFirstOrder(state.document.verification.body)
        : const [],
  );
}
