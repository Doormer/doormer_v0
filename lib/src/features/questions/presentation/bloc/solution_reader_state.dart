part of 'solution_reader_bloc.dart';

abstract class SolutionReaderState extends Equatable {
  const SolutionReaderState();

  @override
  List<Object?> get props => [];
}

class SolutionReaderInitial extends SolutionReaderState {
  const SolutionReaderInitial();
}

class SolutionReaderLoading extends SolutionReaderState {
  const SolutionReaderLoading();
}

class SolutionReaderReady extends SolutionReaderState {
  final SolutionDocument document;
  final int stepIndex;
  final bool rationaleVisible;
  final bool answerRevealed;

  /// The briefing is a mode, not an index. [stepIndex] keeps meaning "index
  /// into document.steps" while this is true, so [isLastStep] — and every
  /// vault-unlock rule built on it — is unaffected by the briefing existing.
  final bool onBriefing;

  final String note;

  /// Where the question sits. Empty when unnamed.
  final String topic;

  /// The theory or rule the solution relies on. Empty when unnamed.
  final String method;

  /// Null until the balance loads. Null keeps the quark pill hidden.
  final int? quarkBalance;

  /// The reward returned by the reveal endpoint. Zero means no reward chip.
  final int quarksEarned;

  /// Increments only when a visible balance receives an earned reward.
  final int rewardFlightId;

  /// True once this page has asked reveal-answer. Prevents a second tab/tap in
  /// the same page from sending the request twice.
  final bool revealRewardRequested;

  const SolutionReaderReady({
    required this.document,
    this.stepIndex = 0,
    this.rationaleVisible = false,
    this.answerRevealed = false,
    this.onBriefing = false,
    this.note = '',
    this.topic = '',
    this.method = '',
    this.quarkBalance,
    this.quarksEarned = 0,
    this.rewardFlightId = 0,
    this.revealRewardRequested = false,
  });

  bool get isFirstStep => stepIndex == 0;

  bool get isLastStep => stepIndex >= document.steps.length - 1;

  bool get hasBriefing => document.approach.body.isNotEmpty;

  SolutionReaderReady copyWith({
    int? stepIndex,
    bool? rationaleVisible,
    bool? answerRevealed,
    bool? onBriefing,
    String? topic,
    String? method,
    int? quarkBalance,
    bool clearQuarkBalance = false,
    int? quarksEarned,
    int? rewardFlightId,
    bool? revealRewardRequested,
  }) {
    return SolutionReaderReady(
      document: document,
      stepIndex: stepIndex ?? this.stepIndex,
      rationaleVisible: rationaleVisible ?? this.rationaleVisible,
      answerRevealed: answerRevealed ?? this.answerRevealed,
      onBriefing: onBriefing ?? this.onBriefing,
      note: note,
      topic: topic ?? this.topic,
      method: method ?? this.method,
      quarkBalance:
          clearQuarkBalance ? null : (quarkBalance ?? this.quarkBalance),
      quarksEarned: quarksEarned ?? this.quarksEarned,
      rewardFlightId: rewardFlightId ?? this.rewardFlightId,
      revealRewardRequested:
          revealRewardRequested ?? this.revealRewardRequested,
    );
  }

  /// [document] is a plain domain entity, so it compares by identity here.
  @override
  List<Object?> get props => [
        document,
        stepIndex,
        rationaleVisible,
        answerRevealed,
        onBriefing,
        note,
        topic,
        method,
        quarkBalance,
        quarksEarned,
        rewardFlightId,
        revealRewardRequested,
      ];
}

class SolutionReaderError extends SolutionReaderState {
  final String message;

  const SolutionReaderError(this.message);

  @override
  List<Object?> get props => [message];
}
