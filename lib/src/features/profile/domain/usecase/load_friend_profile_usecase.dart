import '../entity/friend_profile.dart';
import '../repository/friends_repository.dart';

class LoadFriendProfileUseCase {
  final FriendsRepository repository;

  const LoadFriendProfileUseCase(this.repository);

  Future<FriendProfile> call() => repository.loadProfile();
}
