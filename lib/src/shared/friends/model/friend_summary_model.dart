import 'package:doormer/src/shared/levels/model/level_model.dart';

import '../entity/friend_summary.dart';
import 'card_picture_model.dart';

/// The API's `FriendSummary`: `{friend_id, nickname, picture?, level?}`.
class FriendSummaryModel {
  final String friendId;
  final String nickname;
  final CardPictureModel? picture;

  /// Only on the routes that show friends, and only from level 1.
  final LevelModel? level;

  const FriendSummaryModel({
    required this.friendId,
    required this.nickname,
    this.picture,
    this.level,
  });

  /// Throws when a field is missing or has the wrong type. The data source
  /// reports that as an answer it cannot read.
  factory FriendSummaryModel.fromJson(Map<String, dynamic> json) =>
      FriendSummaryModel(
        friendId: json['friend_id'] as String,
        nickname: json['nickname'] as String,
        picture: CardPictureModel.maybeFromJson(json['picture']),
        level: LevelModel.maybeFromJson(json['level']),
      );

  /// The list of summaries under [key], such as `friends` in the answer to
  /// `/friends/list`.
  static List<FriendSummaryModel> listFromJson(
    Map<String, dynamic> json,
    String key,
  ) =>
      [
        for (final summary in json[key] as List<dynamic>)
          FriendSummaryModel.fromJson(summary as Map<String, dynamic>),
      ];

  FriendSummary toEntity() => FriendSummary(
        friendId: friendId,
        nickname: nickname,
        picture: picture?.toEntity(),
        level: level?.toEntity(),
      );
}
