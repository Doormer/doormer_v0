import 'package:doormer/src/shared/friends/entity/report_reason.dart';

import '../repository/question_sharing_repository.dart';

class ReportSharedQuestionUseCase {
  final QuestionSharingRepository repository;

  const ReportSharedQuestionUseCase(this.repository);

  Future<void> call({
    required String friendId,
    required String questionId,
    required ReportReason reason,
    required String note,
  }) =>
      repository.reportSharedQuestion(
        friendId: friendId,
        questionId: questionId,
        reason: reason,
        note: note,
      );
}
