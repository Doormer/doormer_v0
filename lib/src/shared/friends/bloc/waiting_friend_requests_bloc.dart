import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'waiting_friend_requests_event.dart';
part 'waiting_friend_requests_state.dart';

/// How many friend requests are waiting for the signed-in student, for the
/// dot on the nav bar's Profile item. One for the whole app.
///
/// It only holds the count. Profile's friends bloc tells it the count each
/// time it loads the requests or answers one; it never calls the API.
class WaitingFriendRequestsBloc
    extends Bloc<WaitingFriendRequestsEvent, WaitingFriendRequestsState> {
  WaitingFriendRequestsBloc() : super(const WaitingFriendRequestsState(0)) {
    on<WaitingFriendRequestsCounted>(_onCounted);
  }

  void _onCounted(
    WaitingFriendRequestsCounted event,
    Emitter<WaitingFriendRequestsState> emit,
  ) {
    emit(WaitingFriendRequestsState(event.count));
  }
}
