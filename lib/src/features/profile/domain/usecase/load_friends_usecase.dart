import 'package:doormer/src/shared/friends/entity/friend_summary.dart';

import '../repository/friends_repository.dart';

class LoadFriendsUseCase {
  final FriendsRepository repository;

  const LoadFriendsUseCase(this.repository);

  Future<List<FriendSummary>> call() => repository.loadFriends();
}
