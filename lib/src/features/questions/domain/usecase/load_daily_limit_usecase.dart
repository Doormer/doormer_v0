import 'package:doormer/src/features/questions/domain/entity/daily_limit.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';

class LoadDailyLimitUseCase {
  final QuestionsRepository repository;

  const LoadDailyLimitUseCase(this.repository);

  Future<DailyLimit> call() => repository.loadDailyLimit();
}
