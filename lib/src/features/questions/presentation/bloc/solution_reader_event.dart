part of 'solution_reader_bloc.dart';

abstract class SolutionReaderEvent extends Equatable {
  const SolutionReaderEvent();

  @override
  List<Object?> get props => [];
}

/// Opens the reader. [document] is the solve result handed over through the
/// route. When [document] is null and [questionId] is set, the reader loads
/// that question by address. When both are null, the bundled sample at
/// `/questions/sample/solution` opens and must never pay.
class SolutionReaderStarted extends SolutionReaderEvent {
  final SolutionDocument? document;

  /// The solved question that can pay when the answer opens. Null only for the
  /// bundled sample URL, which must never pay.
  final String? questionId;

  /// Solver commentary handed over alongside [document]. Ignored when
  /// [document] is null, because the sample path reads the note off the
  /// outcome it loads.
  final String note;

  /// Topic handed over alongside [document]. Ignored when [document] is null.
  final String topic;

  /// Method handed over alongside [document]. Ignored when [document] is null.
  final String method;

  const SolutionReaderStarted({
    this.document,
    this.note = '',
    this.topic = '',
    this.method = '',
    this.questionId,
  });

  @override
  List<Object?> get props => [document, note, topic, method, questionId];
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
  final String? questionId;

  const SolutionReaderAnswerRevealed({this.questionId});

  @override
  List<Object?> get props => [questionId];
}
