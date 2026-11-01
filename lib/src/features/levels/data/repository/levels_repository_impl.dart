import '../../domain/entity/active_day_outcome.dart';
import '../../domain/repository/levels_repository.dart';
import '../datasource/levels_remote_datasource.dart';

/// Turns the API's answer into the domain's terms. Failures pass straight
/// through.
class LevelsRepositoryImpl implements LevelsRepository {
  final LevelsRemoteDataSource remoteDataSource;

  const LevelsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ActiveDayOutcome> countActiveDay() async =>
      (await remoteDataSource.countActiveDay()).toEntity();
}
