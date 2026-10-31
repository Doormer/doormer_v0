import '../repository/friends_repository.dart';

class UnblockStudentUseCase {
  final FriendsRepository repository;

  const UnblockStudentUseCase(this.repository);

  Future<void> call(String friendId) => repository.unblockStudent(friendId);
}
