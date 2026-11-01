import '../entity/shared_questions_page.dart';
import '../repository/question_sharing_repository.dart';

class LoadSharedQuestionsUseCase {
  final QuestionSharingRepository repository;

  const LoadSharedQuestionsUseCase(this.repository);

  Future<SharedQuestionsPage> call({String? cursor}) =>
      repository.loadSharedQuestions(cursor: cursor);
}
