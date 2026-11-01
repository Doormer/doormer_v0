import '../entity/active_day_outcome.dart';
import '../repository/levels_repository.dart';

class CountActiveDayUseCase {
  final LevelsRepository repository;

  const CountActiveDayUseCase(this.repository);

  Future<ActiveDayOutcome> call() => repository.countActiveDay();
}
