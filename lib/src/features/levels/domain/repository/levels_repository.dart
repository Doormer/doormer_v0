import '../entity/active_day_outcome.dart';

/// Active days: each day a student opens Doormer signed in counts once, in
/// New Zealand time, however long they stay.
///
/// Throws a `Failure` when the day can't be counted.
abstract class LevelsRepository {
  /// Tells the API the signed-in student is here. The first time each day
  /// counts; asking again the same day changes nothing.
  Future<ActiveDayOutcome> countActiveDay();
}
