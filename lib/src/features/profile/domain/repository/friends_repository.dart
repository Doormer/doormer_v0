import 'package:doormer/src/shared/friends/entity/card_picture.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/friends/entity/report_reason.dart';

import '../entity/found_student.dart';
import '../entity/friend_profile.dart';
import '../entity/friend_request.dart';
import '../entity/picture_choice.dart';

/// The student's friends, as the API holds them. The acting student is
/// always the signed-in one.
///
/// Every method throws a `Failure` whose message a student can read.
abstract class FriendsRepository {
  Future<FriendProfile> loadProfile();

  /// Makes the profile the first time, with its code, and records that the
  /// student agreed to be seen by friends. No [picture] means the nickname's
  /// first letter.
  Future<FriendProfile> saveProfile({
    required String nickname,
    CardPicture? picture,
  });

  /// One choice per card the student owns, in catalog order.
  Future<List<PictureChoice>> loadPictureChoices();

  /// A new friend code. The old one and its invite links stop working.
  Future<FriendProfile> resetCode();

  /// The owner of [friendCode], 8 characters with no dash.
  Future<FoundStudent> findStudent(String friendCode);

  /// Requests waiting for an answer, newest first.
  Future<List<FriendRequest>> loadRequests();

  Future<SendFriendRequestResult> sendRequest(
    String friendCode,
    FriendRequestVia via,
  );

  /// Accepts a request, and answers with the new friend.
  Future<FriendSummary> acceptRequest(String requestId);

  Future<void> declineRequest(String requestId);

  /// By nickname, ignoring case.
  Future<List<FriendSummary>> loadFriends();

  Future<void> removeFriend(String friendId);

  Future<void> blockStudent(String friendId);

  Future<void> unblockStudent(String friendId);

  /// Newest block first.
  Future<List<FriendSummary>> loadBlockedStudents();

  /// [note] is optional: an empty one is not sent.
  Future<void> reportStudent(
    String friendId, {
    required ReportReason reason,
    required String note,
  });
}
