import '../entity/friend_profile.dart';
import '../repository/friends_repository.dart';

class ResetFriendCodeUseCase {
  final FriendsRepository repository;

  const ResetFriendCodeUseCase(this.repository);

  Future<FriendProfile> call() => repository.resetCode();
}
