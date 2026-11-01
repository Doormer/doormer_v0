import '../repository/question_sharing_repository.dart';

class BlockFriendUseCase {
  final QuestionSharingRepository repository;

  const BlockFriendUseCase(this.repository);

  Future<void> call(String friendId) => repository.blockFriend(friendId);
}
