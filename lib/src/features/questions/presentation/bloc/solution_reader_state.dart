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

  const SolutionReaderReady({
    required this.document,
    this.stepIndex = 0,
    this.rationaleVisible = false,
    this.answerRevealed = false,
  });

  bool get isFirstStep => stepIndex == 0;

  bool get isLastStep => stepIndex >= document.steps.length - 1;

  SolutionReaderReady copyWith({
    int? stepIndex,
    bool? rationaleVisible,
    bool? answerRevealed,
  }) {
    return SolutionReaderReady(
      document: document,
      stepIndex: stepIndex ?? this.stepIndex,
      rationaleVisible: rationaleVisible ?? this.rationaleVisible,
      answerRevealed: answerRevealed ?? this.answerRevealed,
    );
  }

  /// [document] is a plain domain entity, so it compares by identity here.
  @override
  List<Object?> get props =>
      [document, stepIndex, rationaleVisible, answerRevealed];
}

class SolutionReaderError extends SolutionReaderState {
  final String message;

  const SolutionReaderError(this.message);

  @override
  List<Object?> get props => [message];
}
