import '../repository/questions_repository.dart';

class LoadQuarkBalanceUseCase {
  final QuestionsRepository repository;

  const LoadQuarkBalanceUseCase(this.repository);

  Future<int> call() => repository.loadQuarkBalance();
}
