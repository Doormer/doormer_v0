import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/shared/friends/bloc/waiting_friend_requests_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts with nothing waiting', () {
    final bloc = WaitingFriendRequestsBloc();

    expect(bloc.state.count, 0);
    expect(bloc.state.hasWaiting, isFalse);
  });

  blocTest<WaitingFriendRequestsBloc, WaitingFriendRequestsState>(
    'holds the latest count it is told',
    build: WaitingFriendRequestsBloc.new,
    act: (bloc) => bloc
      ..add(const WaitingFriendRequestsCounted(2))
      ..add(const WaitingFriendRequestsCounted(0)),
    expect: () => const [
      WaitingFriendRequestsState(2),
      WaitingFriendRequestsState(0),
    ],
  );

  test('a count above nothing shows the dot', () {
    expect(const WaitingFriendRequestsState(1).hasWaiting, isTrue);
  });
}
