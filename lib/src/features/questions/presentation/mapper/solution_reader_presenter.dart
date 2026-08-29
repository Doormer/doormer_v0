import 'package:doormer/src/features/questions/presentation/bloc/solution_reader_bloc.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_segment_order.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_trail_node.dart';
import 'package:flutter/material.dart' show Icons;

/// What pressing the page's one big button does.
///
/// Named here rather than worked out again wherever the button is drawn. The
/// rule used to be written in three places — the button, the swipe handler and
/// the page — and they drifted: the finished button was still being sent to
/// the vault, which had nothing left to open, so it did nothing at all.
enum SolutionCtaAction {
  /// Move on: to the first step from the plan, to the next step, or — once the
  /// answer is out — to the next question entirely.
  advance,

  /// Open the vault.
  reveal,
}

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

  /// What pressing it does.
  final SolutionCtaAction ctaAction;

  /// Whether the button should read as finished. Mint rather than violet, and
  /// only once the answer is actually out.
  final bool ctaSolved;
  final bool canGoBack;

  /// True once the student has left the first screen. Anything that was only
  /// explaining how to get started has been answered by then.
  final bool hasMoved;
  final bool isLastStep;

  /// True while the orientation screen is showing, before step one.
  final bool onBriefing;
  final String briefingTitle;
  final List<OrderedSegment> briefingBody;

  /// Solver caveat shown on the briefing. Empty when there is none.
  final String note;

  final String vaultSolvedLabel;
  final String checkTitle;

  /// Standing bar copy. XP and streak are empty until the mock standing loads.
  final String topic;
  final String questionTitle;
  final String xpLabel;

  /// The number behind [xpLabel]. The counter lags the label while the pellet
  /// is in flight, and it needs the two as a pair to know what has landed and
  /// what is still on its way.
  final int xpTotal;
  final String streakLabel;

  /// True once the student is on the step that decides the day. The streak is
  /// the only thing on the page that can go backwards, and it is worth saying
  /// so at the moment it becomes true rather than leaving it to a colour.
  final bool streakAtStake;

  /// What this step is worth, as it appears on the card sticker. Empty on the
  /// briefing and on the vault — you are not paid for arriving.
  final String stepXpLabel;

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
    required this.ctaAction,
    required this.ctaSolved,
    required this.canGoBack,
    required this.hasMoved,
    required this.isLastStep,
    required this.onBriefing,
    required this.briefingTitle,
    required this.briefingBody,
    required this.note,
    required this.vaultSolvedLabel,
    required this.checkTitle,
    required this.checkBody,
    required this.topic,
    required this.questionTitle,
    required this.xpLabel,
    required this.xpTotal,
    required this.streakLabel,
    required this.streakAtStake,
    required this.stepXpLabel,
  });
}

/// What one step is worth.
///
/// Taken from the prototype: the first step is cheap because it is free, the
/// last is dear because it is the one that gets abandoned. A flat rate makes
/// the middle of a long solution feel like the same nothing every time.
int stepXpValue(int index, int stepCount) {
  if (index == 0) return 10;
  if (index == stepCount - 1) return 20;
  return 15;
}

/// XP banked by reading every step before [index].
/// The vault is strapped with three chains and the working breaks them. Tying
/// them to progress rather than to the unlock means the student watches the
/// answer come loose as they work, instead of only at the end.
///
/// The epsilon absorbs float error: two thirds of the way through a four-step
/// question must break the second chain, not hover just under it.
int _chainsBroken({
  required bool onBriefing,
  required int stepIndex,
  required int stepCount,
}) {
  if (onBriefing) return 0;
  if (stepCount <= 1) return 3;
  final progress = stepIndex / (stepCount - 1);
  return (progress * 3 + 0.0001).floor().clamp(0, 3);
}

int _xpBankedBefore(int index, int stepCount) {
  var total = 0;
  for (var i = 0; i < index; i++) {
    total += stepXpValue(i, stepCount);
  }
  return total;
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

  final profile = state.profile;
  // XP banks on arrival, not on completion: reaching step 3 means steps 1 and
  // 2 are read. The briefing banks nothing, so it shows the opening total.
  final earnedXp = (profile?.bankedXp ?? 0) +
      (onBriefing ? 0 : _xpBankedBefore(state.stepIndex, stepCount));

  return SolutionReaderContent(
    // "of N" is load-bearing: the number alone says where the student is, but
    // not how much is left. Seeing "3 of 3" is what makes the last step feel
    // like the last step.
    levelLabel: 'LEVEL ${state.stepIndex + 1} OF $stepCount',
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
          icon: Icons.flag_rounded,
          shape: SolutionTrailNodeShape.marker,
          travelTo: onBriefing ? null : SolutionTrailNode.briefingPosition,
          // Students rarely think to go back to the plan, so once they have
          // left it, it says it is still there.
          invites: !onBriefing,
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
          travelTo: !onBriefing && i < state.stepIndex ? i : null,
        ),
      // The vault closes the trail so the destination is visible from step
      // one. Amber the moment it can be opened, mint once it is.
      SolutionTrailNode(
        displayNumber: 0,
        state: answerRevealed
            ? SolutionTrailNodeState.done
            : isLastStep
                ? SolutionTrailNodeState.ready
                : SolutionTrailNodeState.upcoming,
        semanticsLabel: answerRevealed ? 'The answer' : 'The answer, locked',
        icon: answerRevealed ? Icons.lock_open_rounded : Icons.lock_rounded,
        shape: SolutionTrailNodeShape.marker,
        chainsBroken: _chainsBroken(
          onBriefing: onBriefing,
          stepIndex: state.stepIndex,
          stepCount: stepCount,
        ),
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
            ? 'Ask another question'
            : isLastStep
                ? 'Reveal answer'
                : 'Next step',
    // A finished page is not a dead end. Once the answer is out the button
    // stops being "you are done" and becomes the way to the next question.
    ctaEnabled: true,
    ctaAction: !answerRevealed && isLastStep && !onBriefing
        ? SolutionCtaAction.reveal
        : SolutionCtaAction.advance,
    ctaSolved: answerRevealed,
    canGoBack: onBriefing ? false : (!state.isFirstStep || hasBriefing),
    hasMoved: !onBriefing && !state.isFirstStep,
    isLastStep: isLastStep,
    onBriefing: onBriefing,
    briefingTitle: 'The plan',
    briefingBody: diagramFirstOrder(state.document.approach.body),
    note: state.note,
    vaultSolvedLabel: 'You solved it in $stepCount '
        '${stepCount == 1 ? 'step' : 'steps'}',
    checkTitle: 'Check it',
    checkBody: answerRevealed
        ? diagramFirstOrder(state.document.verification.body)
        : const [],
    topic: profile?.topic ?? '',
    questionTitle: profile?.questionTitle ?? '',
    xpLabel: profile == null ? '' : '$earnedXp XP',
    xpTotal: earnedXp,
    streakLabel: profile == null ? '' : '${profile.streakDays}-day',
    streakAtStake: !onBriefing && state.isLastStep,
    stepXpLabel:
        onBriefing ? '' : '+${stepXpValue(state.stepIndex, stepCount)} XP',
  );
}
