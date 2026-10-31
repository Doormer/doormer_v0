import 'package:doormer/src/features/questions/domain/entity/daily_limit.dart';
import 'package:doormer/src/features/questions/presentation/bloc/daily_limit_bloc.dart';
import 'package:doormer/src/features/questions/presentation/params/daily_limit_params.dart';

/// Pure function mapping the daily limit to what Solve says about it.
/// Page-invoked only.
///
/// Null while the count is unknown: Solve then says nothing and lets the
/// student ask, because the API enforces the limit either way.
DailyLimitParams? dailyLimitParamsFor(DailyLimitState state) {
  if (state is! DailyLimitKnown) return null;
  final dailyLimit = state.dailyLimit;
  if (dailyLimit.isReached) {
    return DailyLimitParams(
      text: dailyLimitReachedText(dailyLimit),
      isReached: true,
    );
  }
  final left = dailyLimit.questionsLeft;
  return DailyLimitParams(
    text: left == 1 ? '1 question left today' : '$left questions left today',
    isReached: false,
  );
}

/// What Solve says once today's questions are used: when they come back, as
/// a clock time in the student's own zone. A fixed time, never a countdown.
String dailyLimitReachedText(DailyLimit dailyLimit) =>
    "You've used today's questions. "
    'They reset at ${resetTimeLabel(dailyLimit.resetsAt.toLocal())}.';

/// A clock time as a student would say it: "midnight", "noon", "10pm" or
/// "9:30am". [time] is already in the zone to show.
String resetTimeLabel(DateTime time) {
  if (time.minute == 0 && time.hour == 0) return 'midnight';
  if (time.minute == 0 && time.hour == 12) return 'noon';
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minutes =
      time.minute == 0 ? '' : ':${time.minute.toString().padLeft(2, '0')}';
  return '$hour$minutes${time.hour < 12 ? 'am' : 'pm'}';
}
