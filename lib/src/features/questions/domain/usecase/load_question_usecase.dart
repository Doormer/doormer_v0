import '../entity/photo_question_solve_outcome.dart';
import '../repository/questions_repository.dart';

class LoadQuestionUseCase {
  final QuestionsRepository repository;

  const LoadQuestionUseCase(this.repository);

  Future<PhotoQuestionSolveOutcome> call(String questionId) =>
      repository.loadQuestion(questionId);
}
