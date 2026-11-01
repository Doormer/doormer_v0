part of 'level_progress_bloc.dart';

sealed class LevelProgressEvent extends Equatable {
  const LevelProgressEvent();

  @override
  List<Object?> get props => const [];
}

/// A count of the day brought back the student's progress.
class LevelProgressUpdated extends LevelProgressEvent {
  final LevelProgress progress;

  const LevelProgressUpdated(this.progress);

  @override
  List<Object?> get props => [progress];
}

/// A session started: whoever signed in may be another student.
class LevelProgressCleared extends LevelProgressEvent {
  const LevelProgressCleared();
}
