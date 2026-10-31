part of 'daily_limit_bloc.dart';

abstract class DailyLimitState extends Equatable {
  const DailyLimitState();

  @override
  List<Object?> get props => [];
}

/// Nothing read yet, or no read has worked. Solve shows no count and lets the
/// student ask.
class DailyLimitUnknown extends DailyLimitState {
  const DailyLimitUnknown();
}

class DailyLimitKnown extends DailyLimitState {
  final DailyLimit dailyLimit;

  const DailyLimitKnown(this.dailyLimit);

  @override
  List<Object?> get props => [dailyLimit];
}
