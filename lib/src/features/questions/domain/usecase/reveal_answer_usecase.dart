import '../entity/answer_reward.dart';
import '../repository/questions_repository.dart';

class RevealAnswerUseCase {
  final QuestionsRepository repository;

  const RevealAnswerUseCase(this.repository);

  Future<AnswerReward> call(String questionId) =>
      repository.revealAnswer(questionId);
}
