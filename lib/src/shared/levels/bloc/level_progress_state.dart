part of 'level_progress_bloc.dart';

class LevelProgressState extends Equatable {
  /// Null until a count of the day brings it. Profile shows no level strip
  /// until then.
  final LevelProgress? progress;

  const LevelProgressState(this.progress);

  @override
  List<Object?> get props => [progress];
}
