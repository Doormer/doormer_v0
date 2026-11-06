import 'package:bloc/bloc.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/shared/levels/bloc/level_progress_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entity/active_day_outcome.dart';
import '../../domain/usecase/count_active_day_usecase.dart';

part 'active_day_event.dart';
part 'active_day_state.dart';

/// Counts the signed-in student's active day. One for the whole app.
///
/// The nav bar shell asks when it first shows, and whenever the browser tab
/// comes back into view. The API counts each day once, so asking again the
/// same day changes nothing. Each answer's progress goes to the app-wide
/// [LevelProgressBloc], and the state says when a count raised the level,
/// for the shell's pop-up. A count that fails is only logged: the next open
/// or tab return tries again.
///
/// A new session starts it afresh. The answer to a count asked for before
/// then is the last student's, so it changes nothing, and a failure is only
/// logged.
class ActiveDayBloc extends Bloc<ActiveDayEvent, ActiveDayState> {
  final CountActiveDayUseCase countActiveDay;

  /// Told the progress each count brings back. No use case holds it, so
  /// this bloc feeds another, as the friends bloc feeds the requests count.
  final LevelProgressBloc levelProgress;

  /// Goes up by one each time a session starts. A count remembers it, to
  /// tell whether its answer comes back in the session that asked for it.
  int _sessionNumber = 0;

  ActiveDayBloc({required this.countActiveDay, required this.levelProgress})
      : super(const ActiveDayNotCounted()) {
    on<ActiveDayCountRequested>(_onCountRequested);
    on<ActiveDaySessionStarted>(_onSessionStarted);
  }

  Future<void> _onCountRequested(
    ActiveDayCountRequested event,
    Emitter<ActiveDayState> emit,
  ) async {
    // The count on its way covers this one.
    if (state is ActiveDayCounting) return;
    final askedInSession = _sessionNumber;
    emit(const ActiveDayCounting());
    try {
      final outcome = await countActiveDay();
      // Asked for before a new session started: the last student's answer.
      if (askedInSession != _sessionNumber) return;
      levelProgress.add(LevelProgressUpdated(outcome.progress));
      emit(ActiveDayCounted(outcome));
    } on Failure catch (f, stackTrace) {
      if (askedInSession == _sessionNumber) emit(ActiveDayError(f.message));
      AppLogger.error('The active day could not be counted',
          error: f, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      if (askedInSession == _sessionNumber) {
        emit(const ActiveDayError('An unexpected error occurred'));
      }
      AppLogger.error('Counting the active day failed unexpectedly',
          error: e, stackTrace: stackTrace);
    }
  }

  void _onSessionStarted(
    ActiveDaySessionStarted event,
    Emitter<ActiveDayState> emit,
  ) {
    _sessionNumber++;
    emit(const ActiveDayNotCounted());
  }
}
