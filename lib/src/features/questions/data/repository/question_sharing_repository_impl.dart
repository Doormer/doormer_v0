import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/friends/entity/report_reason.dart';

import '../../domain/entity/shared_questions_page.dart';
import '../../domain/repository/question_sharing_repository.dart';
import '../datasource/question_sharing_remote_datasource.dart';

/// Turns the API's answers into the domain's terms. The data source has
/// already turned every problem into a `Failure` a student can read, so
/// failures pass straight through.
class QuestionSharingRepositoryImpl implements QuestionSharingRepository {
  final QuestionSharingRemoteDataSource remoteDataSource;

  const QuestionSharingRepositoryImpl({required this.remoteDataSource});

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
  Future<SharedQuestionsPage> loadSharedQuestions({String? cursor}) async =>
      (await remoteDataSource.sharedQuestions(cursor: cursor)).toEntity();

  @override
  Future<void> removeSharedQuestion(String questionId) =>
      remoteDataSource.removeSharedQuestion(questionId);

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
  Future<void> blockFriend(String friendId) => remoteDataSource.block(friendId);
}
