part of 'daily_limit_bloc.dart';

abstract class DailyLimitEvent extends Equatable {
  const DailyLimitEvent();

  @override
  List<Object?> get props => [];
}

/// Read the count from the API: when Solve opens, when the student comes back
/// to it, when the app resumes, after a send that brings no count back, and
/// when the limit keeps the photo options shut. Never on a timer.
class DailyLimitRequested extends DailyLimitEvent {
  const DailyLimitRequested();
}

/// An ask came back with the count after it, or was turned away with none
/// left.
class DailyLimitReported extends DailyLimitEvent {
  final DailyLimit dailyLimit;

  const DailyLimitReported(this.dailyLimit);

  @override
  List<Object?> get props => [dailyLimit];
}
