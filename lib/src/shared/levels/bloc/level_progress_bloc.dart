import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../entity/level_progress.dart';

part 'level_progress_event.dart';
part 'level_progress_state.dart';

/// The signed-in student's latest level progress, for Profile's level card.
/// One for the whole app.
///
/// It only holds the progress. The levels feature's active day bloc tells it
/// what each count of the day brings back; it never calls the API. A new
/// session clears it, since whoever signs in may be another student.
class LevelProgressBloc extends Bloc<LevelProgressEvent, LevelProgressState> {
  LevelProgressBloc() : super(const LevelProgressState(null)) {
    on<LevelProgressUpdated>(_onUpdated);
    on<LevelProgressCleared>(_onCleared);
  }

  void _onUpdated(
    LevelProgressUpdated event,
    Emitter<LevelProgressState> emit,
  ) {
    emit(LevelProgressState(event.progress));
  }

  void _onCleared(
    LevelProgressCleared event,
    Emitter<LevelProgressState> emit,
  ) {
    emit(const LevelProgressState(null));
  }
}
