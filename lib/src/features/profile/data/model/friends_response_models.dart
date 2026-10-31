import 'package:doormer/src/shared/friends/model/card_picture_model.dart';
import 'package:doormer/src/shared/friends/model/friend_summary_model.dart';

import '../../domain/entity/found_student.dart';
import '../../domain/entity/friend_profile.dart';
import '../../domain/entity/friend_request.dart';
import '../../domain/entity/picture_choice.dart';

// The friends API's answers, one class per answer. Each `fromJson` throws
// when a field is missing, has the wrong type, or holds a value the app does
// not know; the data source reports that as an answer it cannot read.

FriendRelation _relation(String raw) => switch (raw) {
      'none' => FriendRelation.none,
      'request_sent' => FriendRelation.requestSent,
      'request_received' => FriendRelation.requestReceived,
      'friends' => FriendRelation.friends,
      'blocked_by_you' => FriendRelation.blockedByYou,
      'you' => FriendRelation.you,
      _ => throw FormatException('Unknown relation: $raw'),
    };

SendFriendRequestResult _result(String raw) => switch (raw) {
      'sent' => SendFriendRequestResult.sent,
      'now_friends' => SendFriendRequestResult.nowFriends,
      _ => throw FormatException('Unknown send result: $raw'),
    };

/// The API's `FriendProfileResp`. With no profile, `nickname`, `picture` and
/// `friend_code` are left out.
class FriendProfileModel {
  final bool hasProfile;
  final String nickname;
  final CardPictureModel? picture;
  final String friendCode;
  final bool friendsTurnedOff;
  final int waitingRequests;

  const FriendProfileModel({
    required this.hasProfile,
    required this.nickname,
    this.picture,
    required this.friendCode,
    required this.friendsTurnedOff,
    required this.waitingRequests,
  });

  factory FriendProfileModel.fromJson(Map<String, dynamic> json) =>
      FriendProfileModel(
        hasProfile: json['has_profile'] as bool,
        nickname: json['nickname'] as String? ?? '',
        picture: CardPictureModel.maybeFromJson(json['picture']),
        friendCode: json['friend_code'] as String? ?? '',
        friendsTurnedOff: json['friends_turned_off'] as bool,
        waitingRequests: json['waiting_requests'] as int,
      );

  FriendProfile toEntity() => FriendProfile(
        hasProfile: hasProfile,
        nickname: nickname,
        picture: picture?.toEntity(),
        friendCode: friendCode,
        friendsTurnedOff: friendsTurnedOff,
        waitingRequests: waitingRequests,
      );
}

/// One of `pictures` in the answer to `/friends/pictures`.
class PictureChoiceModel {
  final CardPictureModel picture;
  final String name;

  const PictureChoiceModel({required this.picture, required this.name});

  factory PictureChoiceModel.fromJson(Map<String, dynamic> json) =>
      PictureChoiceModel(
        picture: CardPictureModel.fromJson(json),
        name: json['name'] as String,
      );

  static List<PictureChoiceModel> listFromJson(Map<String, dynamic> json) => [
        for (final choice in json['pictures'] as List<dynamic>)
          PictureChoiceModel.fromJson(choice as Map<String, dynamic>),
      ];

  PictureChoice toEntity() =>
      PictureChoice(picture: picture.toEntity(), name: name);
}

/// The answer to `/friends/find`.
class FoundStudentModel {
  final FriendSummaryModel student;
  final FriendRelation relation;

  const FoundStudentModel({required this.student, required this.relation});

  factory FoundStudentModel.fromJson(Map<String, dynamic> json) =>
      FoundStudentModel(
        student: FriendSummaryModel.fromJson(
            json['student'] as Map<String, dynamic>),
        relation: _relation(json['relation'] as String),
      );

  FoundStudent toEntity() =>
      FoundStudent(student: student.toEntity(), relation: relation);
}

/// One of `requests` in the answer to `/friends/requests`.
class FriendRequestModel {
  final String requestId;
  final FriendSummaryModel from;
  final DateTime sentAt;

  const FriendRequestModel({
    required this.requestId,
    required this.from,
    required this.sentAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) =>
      FriendRequestModel(
        requestId: json['request_id'] as String,
        from: FriendSummaryModel.fromJson(json['from'] as Map<String, dynamic>),
        sentAt: DateTime.parse(json['sent_at'] as String),
      );

  static List<FriendRequestModel> listFromJson(Map<String, dynamic> json) => [
        for (final request in json['requests'] as List<dynamic>)
          FriendRequestModel.fromJson(request as Map<String, dynamic>),
      ];

  FriendRequest toEntity() => FriendRequest(
        requestId: requestId,
        from: from.toEntity(),
        sentAt: sentAt,
      );
}

/// The answer to `/friends/requests/send`.
class SendFriendRequestResponseModel {
  final SendFriendRequestResult result;

  const SendFriendRequestResponseModel({required this.result});

  factory SendFriendRequestResponseModel.fromJson(Map<String, dynamic> json) =>
      SendFriendRequestResponseModel(result: _result(json['result'] as String));
}

/// The answer to `/friends/requests/accept`.
class AcceptFriendRequestResponseModel {
  final FriendSummaryModel friend;

  const AcceptFriendRequestResponseModel({required this.friend});

  factory AcceptFriendRequestResponseModel.fromJson(
          Map<String, dynamic> json) =>
      AcceptFriendRequestResponseModel(
        friend:
            FriendSummaryModel.fromJson(json['friend'] as Map<String, dynamic>),
      );
}
