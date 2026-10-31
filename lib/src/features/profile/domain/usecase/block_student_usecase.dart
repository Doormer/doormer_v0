import '../repository/friends_repository.dart';

class BlockStudentUseCase {
  final FriendsRepository repository;

  const BlockStudentUseCase(this.repository);

  Future<void> call(String friendId) => repository.blockStudent(friendId);
}
