part of 'solution_reader_bloc.dart';

abstract class SolutionReaderEvent extends Equatable {
  const SolutionReaderEvent();

  @override
  List<Object?> get props => [];
}

/// Opens the reader. [document] is the solve result handed over through the
/// route; when it is null the reader falls back to the bundled sample, which
/// is what happens on a refresh or a shared link.
class SolutionReaderStarted extends SolutionReaderEvent {
  final SolutionDocument? document;

  const SolutionReaderStarted({this.document});

  @override
  List<Object?> get props => [document];
}

class SolutionReaderAdvanced extends SolutionReaderEvent {
  const SolutionReaderAdvanced();
}

class SolutionReaderWentBack extends SolutionReaderEvent {
  const SolutionReaderWentBack();
}

class SolutionReaderRationaleToggled extends SolutionReaderEvent {
  const SolutionReaderRationaleToggled();
}

class SolutionReaderAnswerRevealed extends SolutionReaderEvent {
  const SolutionReaderAnswerRevealed();
}
