import '../entity/solved_questions_page.dart';
import '../repository/questions_repository.dart';

class LoadSolvedQuestionsUseCase {
  final QuestionsRepository repository;

  const LoadSolvedQuestionsUseCase(this.repository);

  Future<SolvedQuestionsPage> call({String? cursor}) =>
      repository.loadSolvedQuestions(cursor: cursor);
}
