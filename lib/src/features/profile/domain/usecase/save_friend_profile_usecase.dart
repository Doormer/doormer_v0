import 'package:doormer/src/shared/friends/entity/card_picture.dart';

import '../entity/friend_profile.dart';
import '../repository/friends_repository.dart';

class SaveFriendProfileUseCase {
  final FriendsRepository repository;

  const SaveFriendProfileUseCase(this.repository);

  Future<FriendProfile> call({
    required String nickname,
    CardPicture? picture,
  }) =>
      repository.saveProfile(nickname: nickname, picture: picture);
}
