import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';

class LoadSampleSolutionUseCase {
  final QuestionsRepository repository;

  const LoadSampleSolutionUseCase(this.repository);

  Future<PhotoQuestionSolveOutcome> call() => repository.loadSampleSolution();
}
