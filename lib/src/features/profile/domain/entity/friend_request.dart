import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:equatable/equatable.dart';

/// A request to the student, waiting for Accept or Decline.
class FriendRequest extends Equatable {
  final String requestId;
  final FriendSummary from;
  final DateTime sentAt;

  const FriendRequest({
    required this.requestId,
    required this.from,
    required this.sentAt,
  });

  @override
  List<Object?> get props => [requestId, from, sentAt];
}

/// How a request was sent: by typing a code, or from an invite link.
enum FriendRequestVia { code, link }

/// What sending a request did. Two students who send each other a request
/// become friends at once.
enum SendFriendRequestResult { sent, nowFriends }
