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
