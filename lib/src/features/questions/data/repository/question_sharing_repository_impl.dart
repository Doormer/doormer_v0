import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/friends/entity/report_reason.dart';

import '../../domain/entity/shared_questions_page.dart';
import '../../domain/repository/question_sharing_repository.dart';
import '../datasource/question_sharing_remote_datasource.dart';

/// Turns the API's answers into the domain's terms. The data source has
/// already turned every problem into a `Failure` a student can read, so
/// failures pass straight through.
///
/// A read of Shared with me waits for any Remove or Block still on its way,
/// so it never lists a question the student has just taken out.
class QuestionSharingRepositoryImpl implements QuestionSharingRepository {
  final QuestionSharingRemoteDataSource remoteDataSource;

  /// Answers once every Remove and Block asked for so far has answered,
  /// whether it worked or not.
  Future<void> _changesAnswered = Future.value();

  QuestionSharingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<FriendSummary>> loadFriends() async => [
        for (final friend in await remoteDataSource.friends())
          friend.toEntity(),
      ];

  @override
  Future<List<FriendSummary>> share(
    String questionId,
    List<String> friendIds,
  ) async =>
      [
        for (final friend
            in await remoteDataSource.share(questionId, friendIds))
          friend.toEntity(),
      ];

  @override
  Future<void> stopSharing(String questionId) =>
      remoteDataSource.stopSharing(questionId);

  @override
  Future<SharedQuestionsPage> loadSharedQuestions({String? cursor}) async {
    await _changesAnswered;
    return (await remoteDataSource.sharedQuestions(cursor: cursor)).toEntity();
  }

  @override
  Future<void> removeSharedQuestion(String questionId) =>
      _readsWaitFor(remoteDataSource.removeSharedQuestion(questionId));

  @override
  Future<void> reportSharedQuestion({
    required String friendId,
    required String questionId,
    required ReportReason reason,
    required String note,
  }) =>
      remoteDataSource.report(
        friendId: friendId,
        questionId: questionId,
        reason: reason,
        note: note,
      );

  @override
  Future<void> blockFriend(String friendId) =>
      _readsWaitFor(remoteDataSource.block(friendId));

  /// Makes reads of Shared with me wait until [change] has answered, however
  /// it went, and hands it back as it is: its failure is the caller's.
  Future<void> _readsWaitFor(Future<void> change) {
    _changesAnswered = Future.wait([
      _changesAnswered,
      change.catchError((_) {}),
    ]);
    return change;
  }
}
