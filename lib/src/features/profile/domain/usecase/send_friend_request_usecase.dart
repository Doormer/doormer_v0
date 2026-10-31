import '../entity/friend_request.dart';
import '../repository/friends_repository.dart';

class SendFriendRequestUseCase {
  final FriendsRepository repository;

  const SendFriendRequestUseCase(this.repository);

  /// [friendCode] is 8 characters with no dash.
  Future<SendFriendRequestResult> call(
    String friendCode,
    FriendRequestVia via,
  ) =>
      repository.sendRequest(friendCode, via);
}
