import 'package:doormer/src/shared/friends/entity/friend_summary.dart';

import '../repository/question_sharing_repository.dart';

class ShareQuestionUseCase {
  final QuestionSharingRepository repository;

  const ShareQuestionUseCase(this.repository);

  /// Answers with every friend [questionId] is now shared with.
  Future<List<FriendSummary>> call(String questionId, List<String> friendIds) =>
      repository.share(questionId, friendIds);
}
