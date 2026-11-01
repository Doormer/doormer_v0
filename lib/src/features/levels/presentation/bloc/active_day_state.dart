part of 'active_day_bloc.dart';

sealed class ActiveDayState extends Equatable {
  const ActiveDayState();

  @override
  List<Object?> get props => const [];
}

/// Nothing counted since the app opened or the session started.
class ActiveDayNotCounted extends ActiveDayState {
  const ActiveDayNotCounted();
}

/// A count is on its way.
class ActiveDayCounting extends ActiveDayState {
  const ActiveDayCounting();
}

/// The API answered: [outcome] says whether today was new, and whether it
/// raised the level.
class ActiveDayCounted extends ActiveDayState {
  final ActiveDayOutcome outcome;

  const ActiveDayCounted(this.outcome);

  @override
  List<Object?> get props => [outcome];
}

/// Counting failed. Nothing shows it: the next open or tab return tries
/// again.
class ActiveDayError extends ActiveDayState {
  final String message;

  const ActiveDayError(this.message);

  @override
  List<Object?> get props => [message];
}
