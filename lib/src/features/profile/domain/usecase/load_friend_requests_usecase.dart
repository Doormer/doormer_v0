import '../entity/friend_request.dart';
import '../repository/friends_repository.dart';

class LoadFriendRequestsUseCase {
  final FriendsRepository repository;

  const LoadFriendRequestsUseCase(this.repository);

  Future<List<FriendRequest>> call() => repository.loadRequests();
}
