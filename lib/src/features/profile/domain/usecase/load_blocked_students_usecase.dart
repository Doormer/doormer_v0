import 'package:doormer/src/shared/friends/entity/friend_summary.dart';

import '../repository/friends_repository.dart';

class LoadBlockedStudentsUseCase {
  final FriendsRepository repository;

  const LoadBlockedStudentsUseCase(this.repository);

  Future<List<FriendSummary>> call() => repository.loadBlockedStudents();
}
