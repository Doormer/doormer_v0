part of 'waiting_friend_requests_bloc.dart';

sealed class WaitingFriendRequestsEvent extends Equatable {
  const WaitingFriendRequestsEvent();

  @override
  List<Object?> get props => const [];
}

/// The requests were counted afresh.
class WaitingFriendRequestsCounted extends WaitingFriendRequestsEvent {
  final int count;

  const WaitingFriendRequestsCounted(this.count);

  @override
  List<Object?> get props => [count];
}
