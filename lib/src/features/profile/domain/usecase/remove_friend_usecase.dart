import '../repository/friends_repository.dart';

class RemoveFriendUseCase {
  final FriendsRepository repository;

  const RemoveFriendUseCase(this.repository);

  Future<void> call(String friendId) => repository.removeFriend(friendId);
}
