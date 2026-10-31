import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/features/questions/domain/entity/daily_limit.dart';

/// The API turned a photo away because the student has no questions left
/// today. Sending it again won't work until [dailyLimit] resets.
class DailyLimitReachedFailure extends Failure {
  /// None left, and when they come back.
  final DailyLimit dailyLimit;

  DailyLimitReachedFailure(this.dailyLimit)
      : super("You've used today's questions.");
}

/// The API turned a photo away because another of the student's photos is
/// still being solved. Sending the same photo again in a moment works.
class PhotoBeingSolvedFailure extends Failure {
  PhotoBeingSolvedFailure()
      : super('Your last photo is still being solved. Try again in a moment.');
}
