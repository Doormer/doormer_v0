import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/friends/entity/report_reason.dart';

import '../entity/shared_questions_page.dart';

/// Sharing solved questions with friends, and what a student can do with a
/// question a friend shared with them.
abstract class QuestionSharingRepository {
  /// The student's friends, by nickname: who a question can be shared with.
  Future<List<FriendSummary>> loadFriends();

  /// Shares [questionId] with [friendIds], 1 to 10 of them, and answers with
  /// every friend it is now shared with, by nickname.
  Future<List<FriendSummary>> share(String questionId, List<String> friendIds);

  /// Takes [questionId] out of every friend's Shared with me.
  Future<void> stopSharing(String questionId);

  /// One page of Shared with me, newest share first. No cursor asks for the
  /// first page.
  Future<SharedQuestionsPage> loadSharedQuestions({String? cursor});

  /// Takes [questionId] out of the student's own Shared with me.
  Future<void> removeSharedQuestion(String questionId);

  /// Reports [friendId] to the Doormer team, with [questionId], which they
  /// shared with the student.
  Future<void> reportSharedQuestion({
    required String friendId,
    required String questionId,
    required ReportReason reason,
    required String note,
  });

  /// Blocks [friendId], which also ends every share between the two.
  Future<void> blockFriend(String friendId);
}
