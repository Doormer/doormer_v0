import '../repository/question_sharing_repository.dart';

class StopSharingQuestionUseCase {
  final QuestionSharingRepository repository;

  const StopSharingQuestionUseCase(this.repository);

  Future<void> call(String questionId) => repository.stopSharing(questionId);
}
