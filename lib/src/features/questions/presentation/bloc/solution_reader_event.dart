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

  /// Solver commentary handed over alongside [document]. Ignored when
  /// [document] is null, because the sample path reads the note off the
  /// outcome it loads.
  final String note;

  const SolutionReaderStarted({this.document, this.note = ''});

  @override
  List<Object?> get props => [document, note];
}

class SolutionReaderAdvanced extends SolutionReaderEvent {
  const SolutionReaderAdvanced();
}

class SolutionReaderWentBack extends SolutionReaderEvent {
  const SolutionReaderWentBack();
}

/// Returns to a place the student has already been, by tapping its node.
///
/// [position] is a zero-based step index, or [briefing] for the plan at the
/// head of the trail. Travel is backwards only: the trail is a record of
/// ground covered, not a way to skip the working.
class SolutionReaderTravelled extends SolutionReaderEvent {
  static const int briefing = -1;

  final int position;

  const SolutionReaderTravelled(this.position);

  @override
  List<Object?> get props => [position];
}

class SolutionReaderRationaleToggled extends SolutionReaderEvent {
  const SolutionReaderRationaleToggled();
}

class SolutionReaderAnswerRevealed extends SolutionReaderEvent {
  const SolutionReaderAnswerRevealed();
}
