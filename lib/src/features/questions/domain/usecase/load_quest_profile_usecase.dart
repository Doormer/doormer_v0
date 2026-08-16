import 'package:doormer/src/features/questions/domain/entity/quest_profile.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';

class LoadQuestProfileUseCase {
  final QuestionsRepository repository;

  const LoadQuestProfileUseCase(this.repository);

  Future<QuestProfile> call() => repository.loadQuestProfile();
}
