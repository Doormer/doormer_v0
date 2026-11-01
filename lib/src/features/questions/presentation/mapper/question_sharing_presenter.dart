import 'package:doormer/src/shared/friends/entity/friend_summary.dart';

/// How many friends "Shared with" names before it counts the rest.
const _namedFriends = 3;

/// "Shared with Sam, Alex": the friends by nickname, three at most, then how
/// many more, as in "Shared with Sam, Alex, Kate and 2 more". Empty when the
/// question is shared with no one.
String sharedWithLabel(List<FriendSummary> sharedWith) {
  if (sharedWith.isEmpty) return '';
  final named = [
    for (final friend in sharedWith.take(_namedFriends)) friend.nickname,
  ].join(', ');
  final more = sharedWith.length - _namedFriends;
  return more > 0 ? 'Shared with $named and $more more' : 'Shared with $named';
}

/// "Shared by Sam".
String sharedByLabel(FriendSummary sharedBy) =>
    'Shared by ${sharedBy.nickname}';
