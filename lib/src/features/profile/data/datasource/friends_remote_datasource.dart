import 'package:dio/dio.dart';
import 'package:doormer/src/core/connection/dio_exception_mapper.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/shared/friends/entity/card_picture.dart';
import 'package:doormer/src/shared/friends/friends_messages.dart';
import 'package:doormer/src/shared/friends/model/friend_summary_model.dart';

import '../../domain/entity/friend_request.dart';
import '../../domain/entity/report_reason.dart';
import '../model/friends_response_models.dart';

/// The friends routes, one method each, named as the API names them. A
/// friend's collection is read by the collection feature.
///
/// Every method throws a [Failure] whose message a student can read. What the
/// server said is logged, never shown.
abstract class FriendsRemoteDataSource {
  Future<FriendProfileModel> profile();

  Future<FriendProfileModel> saveProfile({
    required String nickname,
    CardPicture? picture,
  });

  Future<List<PictureChoiceModel>> pictures();

  Future<FriendProfileModel> resetCode();

  Future<FoundStudentModel> find(String friendCode);

  Future<List<FriendRequestModel>> requests();

  Future<SendFriendRequestResponseModel> sendRequest(
    String friendCode,
    FriendRequestVia via,
  );

  Future<AcceptFriendRequestResponseModel> acceptRequest(String requestId);

  Future<void> declineRequest(String requestId);

  Future<List<FriendSummaryModel>> friends();

  Future<void> remove(String friendId);

  Future<void> block(String friendId);

  Future<void> unblock(String friendId);

  Future<List<FriendSummaryModel>> blocked();

  Future<void> report(String friendId, ReportReason reason, String note);
}

class FriendsRemoteDataSourceImpl implements FriendsRemoteDataSource {
  /// The words for the statuses any friends call can answer with.
  static const _anyCallRefusals = {
    403: FriendsMessages.turnedOff,
    429: FriendsMessages.doneTooOftenToday,
  };

  final Dio dio;

  const FriendsRemoteDataSourceImpl({required this.dio});

  @override
  Future<FriendProfileModel> profile() => _post(
        '/v1/friends/profile',
        const {},
        FriendProfileModel.fromJson,
        callMessage: FriendsMessages.couldNotLoadFriends,
      );

  @override
  Future<FriendProfileModel> saveProfile({
    required String nickname,
    CardPicture? picture,
  }) =>
      _post(
        '/v1/friends/profile/save',
        {
          'nickname': nickname,
          // Both or neither; empty strings mean no picture.
          'picture_deck_id': picture?.deckId ?? '',
          'picture_card_id': picture?.cardId ?? '',
        },
        FriendProfileModel.fromJson,
        callMessage: FriendsMessages.couldNotSaveProfile,
        refusals: const {422: FriendsMessages.pickDifferentNickname},
      );

  @override
  Future<List<PictureChoiceModel>> pictures() => _post(
        '/v1/friends/pictures',
        const {},
        PictureChoiceModel.listFromJson,
        callMessage: FriendsMessages.couldNotLoadPictures,
      );

  @override
  Future<FriendProfileModel> resetCode() => _post(
        '/v1/friends/code/reset',
        const {},
        FriendProfileModel.fromJson,
        callMessage: FriendsMessages.couldNotResetCode,
      );

  @override
  Future<FoundStudentModel> find(String friendCode) => _post(
        '/v1/friends/find',
        {'friend_code': friendCode},
        FoundStudentModel.fromJson,
        callMessage: FriendsMessages.couldNotFind,
        refusals: const {404: FriendsMessages.codeNotFound},
      );

  @override
  Future<List<FriendRequestModel>> requests() => _post(
        '/v1/friends/requests',
        const {},
        FriendRequestModel.listFromJson,
        callMessage: FriendsMessages.couldNotLoadFriends,
      );

  @override
  Future<SendFriendRequestResponseModel> sendRequest(
    String friendCode,
    FriendRequestVia via,
  ) =>
      _post(
        '/v1/friends/requests/send',
        {'friend_code': friendCode, 'via': via.name},
        SendFriendRequestResponseModel.fromJson,
        callMessage: FriendsMessages.couldNotSendRequest,
        refusals: const {
          // The app never offers Send to a friend or a blocked student, so a
          // 409 means 100 friends.
          409: FriendsMessages.youHaveHundredFriends,
          422: FriendsMessages.yourOwnCode,
        },
      );

  @override
  Future<AcceptFriendRequestResponseModel> acceptRequest(String requestId) =>
      _post(
        '/v1/friends/requests/accept',
        {'request_id': requestId},
        AcceptFriendRequestResponseModel.fromJson,
        callMessage: FriendsMessages.couldNotAcceptRequest,
        refusals: const {
          404: FriendsMessages.requestExpired,
          409: FriendsMessages.oneOfYouHasHundredFriends,
        },
      );

  @override
  Future<void> declineRequest(String requestId) => _send(
        '/v1/friends/requests/decline',
        {'request_id': requestId},
        callMessage: FriendsMessages.couldNotDeclineRequest,
      );

  @override
  Future<List<FriendSummaryModel>> friends() => _post(
        '/v1/friends/list',
        const {},
        (json) => FriendSummaryModel.listFromJson(json, 'friends'),
        callMessage: FriendsMessages.couldNotLoadFriends,
      );

  @override
  Future<void> remove(String friendId) => _send(
        '/v1/friends/remove',
        {'friend_id': friendId},
        callMessage: FriendsMessages.couldNotRemoveFriend,
      );

  @override
  Future<void> block(String friendId) => _send(
        '/v1/friends/block',
        {'friend_id': friendId},
        callMessage: FriendsMessages.couldNotBlock,
        refusals: const {404: FriendsMessages.studentNotFound},
      );

  @override
  Future<void> unblock(String friendId) => _send(
        '/v1/friends/unblock',
        {'friend_id': friendId},
        callMessage: FriendsMessages.couldNotUnblock,
      );

  @override
  Future<List<FriendSummaryModel>> blocked() => _post(
        '/v1/friends/blocked',
        const {},
        (json) => FriendSummaryModel.listFromJson(json, 'blocked'),
        callMessage: FriendsMessages.couldNotLoadBlocked,
      );

  @override
  Future<void> report(String friendId, ReportReason reason, String note) =>
      _send(
        '/v1/friends/report',
        {
          'friend_id': friendId,
          'reason': _reasonName(reason),
          if (note.isNotEmpty) 'note': note,
        },
        callMessage: FriendsMessages.couldNotReport,
        refusals: const {404: FriendsMessages.studentNotFound},
      );

  static String _reasonName(ReportReason reason) => switch (reason) {
        ReportReason.rudeNickname => 'rude_nickname',
        ReportReason.bullying => 'bullying',
        ReportReason.pretending => 'pretending',
        ReportReason.other => 'other',
      };

  /// Posts [body] to [path] and reads the answer with [parse]. An answer it
  /// cannot read fails with [callMessage].
  Future<T> _post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic> json) parse, {
    required String callMessage,
    Map<int, String> refusals = const {},
  }) async {
    final response =
        await _send(path, body, callMessage: callMessage, refusals: refusals);
    try {
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const FormatException('The response is not a JSON object');
      }
      return parse(data);
    } catch (e, stackTrace) {
      AppLogger.error('$path answered with a response the app cannot read',
          error: e, stackTrace: stackTrace);
      throw UnknownFailure(callMessage);
    }
  }

  /// Posts [body] to [path]. A status in [refusals], or one any call can
  /// answer with, fails with its own words; anything else fails with
  /// [callMessage].
  Future<Response<dynamic>> _send(
    String path,
    Map<String, dynamic> body, {
    required String callMessage,
    Map<int, String> refusals = const {},
  }) async {
    try {
      return await dio.post(path, data: body);
    } on DioException catch (e, stackTrace) {
      AppLogger.error('$path failed', error: e, stackTrace: stackTrace);
      final status = e.response?.statusCode;
      final words = e.type == DioExceptionType.badResponse
          ? {..._anyCallRefusals, ...refusals}[status]
          : null;
      if (status != null && words != null) throw RefusedFailure(status, words);
      throw dioExceptionToFailure(e, userFacingMessage: callMessage);
    }
  }
}
