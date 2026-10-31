part of 'waiting_friend_requests_bloc.dart';

class WaitingFriendRequestsState extends Equatable {
  final int count;

  const WaitingFriendRequestsState(this.count);

  /// Whether Profile's nav item shows its dot.
  bool get hasWaiting => count > 0;

  @override
  List<Object?> get props => [count];
}
