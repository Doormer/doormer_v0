import 'package:doormer/src/shared/friends/entity/report_reason.dart';

import '../repository/friends_repository.dart';

class ReportStudentUseCase {
  final FriendsRepository repository;

  const ReportStudentUseCase(this.repository);

  Future<void> call(
    String friendId, {
    required ReportReason reason,
    required String note,
  }) =>
      repository.reportStudent(friendId, reason: reason, note: note);
}
