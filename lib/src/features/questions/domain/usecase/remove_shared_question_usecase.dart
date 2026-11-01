import '../repository/question_sharing_repository.dart';

class RemoveSharedQuestionUseCase {
  final QuestionSharingRepository repository;

  const RemoveSharedQuestionUseCase(this.repository);

  Future<void> call(String questionId) =>
      repository.removeSharedQuestion(questionId);
}
