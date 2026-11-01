part of 'active_day_bloc.dart';

sealed class ActiveDayEvent extends Equatable {
  const ActiveDayEvent();

  @override
  List<Object?> get props => const [];
}

/// Count today as an active day: the nav bar shell first showed, or the
/// browser tab came back into view.
class ActiveDayCountRequested extends ActiveDayEvent {
  const ActiveDayCountRequested();
}

/// A session started: whoever signed in may be another student, so the
/// answer to a count asked for before is the last student's.
class ActiveDaySessionStarted extends ActiveDayEvent {
  const ActiveDaySessionStarted();
}
