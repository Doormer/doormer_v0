import 'package:doormer/src/shared/friends/entity/friend_summary.dart';

import '../repository/question_sharing_repository.dart';

class LoadFriendsToShareWithUseCase {
  final QuestionSharingRepository repository;

  const LoadFriendsToShareWithUseCase(this.repository);

  Future<List<FriendSummary>> call() => repository.loadFriends();
}
