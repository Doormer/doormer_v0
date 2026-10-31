import 'package:doormer/src/shared/friends/entity/friend_summary.dart';

import '../repository/friends_repository.dart';

class AcceptFriendRequestUseCase {
  final FriendsRepository repository;

  const AcceptFriendRequestUseCase(this.repository);

  Future<FriendSummary> call(String requestId) =>
      repository.acceptRequest(requestId);
}
