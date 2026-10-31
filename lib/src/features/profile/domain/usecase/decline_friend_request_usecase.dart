import '../repository/friends_repository.dart';

class DeclineFriendRequestUseCase {
  final FriendsRepository repository;

  const DeclineFriendRequestUseCase(this.repository);

  Future<void> call(String requestId) => repository.declineRequest(requestId);
}
