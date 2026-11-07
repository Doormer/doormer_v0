import 'package:doormer/src/shared/friends/entity/card_picture.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/friends/entity/report_reason.dart';

import '../../domain/entity/found_student.dart';
import '../../domain/entity/friend_profile.dart';
import '../../domain/entity/friend_request.dart';
import '../../domain/entity/picture_choice.dart';
import '../../domain/repository/friends_repository.dart';
import '../datasource/friends_remote_datasource.dart';

/// Turns the API's answers into the domain's terms. The data source has
/// already turned every problem into a `Failure` a student can read, so
/// failures pass straight through.
class FriendsRepositoryImpl implements FriendsRepository {
  final FriendsRemoteDataSource remoteDataSource;

  const FriendsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<FriendProfile> loadProfile() async =>
      (await remoteDataSource.profile()).toEntity();

  @override
  Future<FriendProfile> saveProfile({
    required String nickname,
    CardPicture? picture,
  }) async =>
      (await remoteDataSource.saveProfile(nickname: nickname, picture: picture))
          .toEntity();

  @override
  Future<List<PictureChoice>> loadPictureChoices() async => [
        for (final choice in await remoteDataSource.pictures())
          choice.toEntity(),
      ];

  @override
  Future<FriendProfile> resetCode() async =>
      (await remoteDataSource.resetCode()).toEntity();

  @override
  Future<FoundStudent> findStudent(String friendCode) async =>
      (await remoteDataSource.find(friendCode)).toEntity();

  @override
  Future<List<FriendRequest>> loadRequests() async => [
        for (final request in await remoteDataSource.requests())
          request.toEntity(),
      ];

  @override
  Future<SendFriendRequestResult> sendRequest(
    String friendCode,
    FriendRequestVia via,
  ) async =>
      (await remoteDataSource.sendRequest(friendCode, via)).result;

  @override
  Future<FriendSummary> acceptRequest(String requestId) async =>
      (await remoteDataSource.acceptRequest(requestId)).friend.toEntity();

  @override
  Future<void> declineRequest(String requestId) =>
      remoteDataSource.declineRequest(requestId);

  @override
  Future<List<FriendSummary>> loadFriends() async => [
        for (final friend in await remoteDataSource.friends())
          friend.toEntity(),
      ];

  @override
  Future<void> removeFriend(String friendId) =>
      remoteDataSource.remove(friendId);

  @override
  Future<void> blockStudent(String friendId) =>
      remoteDataSource.block(friendId);

  @override
  Future<void> unblockStudent(String friendId) =>
      remoteDataSource.unblock(friendId);

  @override
  Future<List<FriendSummary>> loadBlockedStudents() async => [
        for (final student in await remoteDataSource.blocked())
          student.toEntity(),
      ];

  @override
  Future<void> reportStudent(
    String friendId, {
    required ReportReason reason,
    required String note,
  }) =>
      remoteDataSource.report(friendId, reason, note);
}
