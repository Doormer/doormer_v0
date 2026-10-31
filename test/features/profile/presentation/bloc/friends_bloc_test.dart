import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/profile/domain/entity/friend_profile.dart';
import 'package:doormer/src/features/profile/domain/entity/friend_request.dart';
import 'package:doormer/src/features/profile/domain/entity/report_reason.dart';
import 'package:doormer/src/features/profile/domain/usecase/accept_friend_request_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/block_student_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/decline_friend_request_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/load_friend_profile_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/load_friend_requests_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/load_friends_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/remove_friend_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/report_student_usecase.dart';
import 'package:doormer/src/features/profile/presentation/bloc/friends_bloc.dart';
import 'package:doormer/src/shared/friends/bloc/waiting_friend_requests_bloc.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_friends_repository.dart';

void main() {
  setUpAll(AppLogger.disable);

  late FakeFriendsRepository repository;
  late WaitingFriendRequestsBloc waiting;

  setUp(() {
    repository = FakeFriendsRepository();
    waiting = WaitingFriendRequestsBloc();
  });

  FriendsBloc build() => FriendsBloc(
        loadProfile: LoadFriendProfileUseCase(repository),
        loadRequests: LoadFriendRequestsUseCase(repository),
        loadFriends: LoadFriendsUseCase(repository),
        acceptRequest: AcceptFriendRequestUseCase(repository),
        declineRequest: DeclineFriendRequestUseCase(repository),
        removeFriend: RemoveFriendUseCase(repository),
        blockStudent: BlockStudentUseCase(repository),
        reportStudent: ReportStudentUseCase(repository),
        waitingRequests: waiting,
      );

  /// What Profile shows of Kai's friends: at the start, unless told
  /// otherwise.
  FriendsReady ready({
    List<FriendRequest>? requests,
    List<FriendSummary> friends = const [alex, sam],
    Set<String> answeringRequestIds = const {},
    Set<String> changingFriendIds = const {},
    ReportStatus reportStatus = ReportStatus.unsent,
    String? errorMessage,
  }) =>
      FriendsReady(
        profile: kaiProfile,
        requests: requests ?? [ruaRequest],
        friends: friends,
        answeringRequestIds: answeringRequestIds,
        changingFriendIds: changingFriendIds,
        reportStatus: reportStatus,
        errorMessage: errorMessage,
      );

  group('loading', () {
    blocTest<FriendsBloc, FriendsState>(
      'shows the profile, the requests and the friends, and counts the '
      'requests for the dot',
      build: build,
      act: (bloc) => bloc.add(const FriendsStarted()),
      expect: () => [ready()],
      verify: (_) => expect(waiting.state.count, 1),
    );

    blocTest<FriendsBloc, FriendsState>(
      'before setup, offers setup and reads nothing else',
      build: build,
      setUp: () => repository.profile = const FriendProfile(
        hasProfile: false,
        nickname: '',
        friendCode: '',
        friendsTurnedOff: false,
        waitingRequests: 0,
      ),
      act: (bloc) => bloc.add(const FriendsStarted()),
      expect: () => [const FriendsNotSetUp()],
      verify: (_) {
        expect(repository.calls, ['loadProfile']);
        expect(waiting.state.count, 0);
      },
    );

    blocTest<FriendsBloc, FriendsState>(
      'with friends turned off, says so and reads nothing else',
      build: build,
      setUp: () => repository.profile = const FriendProfile(
        hasProfile: true,
        nickname: 'Kai',
        friendCode: kaiCode,
        friendsTurnedOff: true,
        waitingRequests: 0,
      ),
      act: (bloc) => bloc.add(const FriendsStarted()),
      expect: () => [const FriendsTurnedOff()],
      verify: (_) {
        expect(repository.calls, ['loadProfile']);
        expect(waiting.state.count, 0);
      },
    );

    blocTest<FriendsBloc, FriendsState>(
      'a load that fails says why',
      build: build,
      setUp: () => repository.failNext['loadFriends'] =
          NetworkFailure("We couldn't load your friends."),
      act: (bloc) => bloc.add(const FriendsStarted()),
      expect: () => [const FriendsError("We couldn't load your friends.")],
    );

    blocTest<FriendsBloc, FriendsState>(
      'an unexpected error says the friends could not load',
      build: build,
      setUp: () => repository.failNext['loadProfile'] = StateError('boom'),
      act: (bloc) => bloc.add(const FriendsStarted()),
      expect: () => [const FriendsError("We couldn't load your friends.")],
    );

    blocTest<FriendsBloc, FriendsState>(
      'Try again loads with the spinner',
      build: build,
      seed: () => const FriendsError("We couldn't load your friends."),
      act: (bloc) => bloc.add(const FriendsRetried()),
      expect: () => [const FriendsLoading(), ready()],
    );
  });

  group('refreshing', () {
    final hemi = FriendRequest(
      requestId: '10',
      from: nia,
      sentAt: DateTime.utc(2026, 10, 26, 10),
    );

    blocTest<FriendsBloc, FriendsState>(
      'quietly shows a request that arrived, and counts it',
      build: build,
      seed: ready,
      setUp: () => repository.requests = [hemi, ruaRequest],
      act: (bloc) => bloc.add(const FriendsRefreshRequested()),
      expect: () => [
        ready(requests: [hemi, ruaRequest]),
      ],
      verify: (_) => expect(waiting.state.count, 2),
    );

    blocTest<FriendsBloc, FriendsState>(
      'a refresh that fails leaves the page as it was',
      build: build,
      seed: ready,
      setUp: () => repository.failNext['loadRequests'] = NetworkFailure(),
      act: (bloc) => bloc.add(const FriendsRefreshRequested()),
      expect: () => <FriendsState>[],
    );

    blocTest<FriendsBloc, FriendsState>(
      'after a failed load, tries again with the spinner',
      build: build,
      seed: () => const FriendsError("We couldn't load your friends."),
      act: (bloc) => bloc.add(const FriendsRefreshRequested()),
      expect: () => [const FriendsLoading(), ready()],
    );
  });

  group('answering a request', () {
    blocTest<FriendsBloc, FriendsState>(
      'Accept waits for the answer, then shows the new friend, and the dot '
      'goes',
      build: build,
      seed: ready,
      act: (bloc) => bloc.add(const FriendRequestAccepted('9')),
      expect: () => [
        ready(answeringRequestIds: {'9'}),
        ready(requests: const [], friends: const [alex, rua, sam]),
      ],
      verify: (_) {
        expect(repository.calls.first, 'acceptRequest 9');
        expect(waiting.state.count, 0);
      },
    );

    blocTest<FriendsBloc, FriendsState>(
      'a second tap while the first waits does nothing',
      build: build,
      seed: ready,
      setUp: () => repository.hold = Completer<void>(),
      act: (bloc) async {
        bloc
          ..add(const FriendRequestAccepted('9'))
          ..add(const FriendRequestAccepted('9'));
        await Future<void>.delayed(Duration.zero);
        repository.hold!.complete();
      },
      verify: (_) => expect(
        repository.calls.where((call) => call == 'acceptRequest 9'),
        hasLength(1),
      ),
    );

    blocTest<FriendsBloc, FriendsState>(
      'an expired request says so, and goes from the list',
      build: build,
      seed: ready,
      setUp: () {
        repository.failNext['acceptRequest'] =
            RefusedFailure(404, 'That request has expired.');
        repository.requests = [];
      },
      act: (bloc) => bloc.add(const FriendRequestAccepted('9')),
      expect: () => [
        ready(answeringRequestIds: {'9'}),
        ready(requests: const [], errorMessage: 'That request has expired.'),
      ],
    );

    blocTest<FriendsBloc, FriendsState>(
      'Decline takes the request away',
      build: build,
      seed: ready,
      act: (bloc) => bloc.add(const FriendRequestDeclined('9')),
      expect: () => [
        ready(answeringRequestIds: {'9'}),
        ready(requests: const []),
      ],
      verify: (_) => expect(repository.calls.first, 'declineRequest 9'),
    );
  });

  group('removing and blocking', () {
    blocTest<FriendsBloc, FriendsState>(
      'Remove takes the friend away',
      build: build,
      seed: ready,
      act: (bloc) => bloc.add(const FriendRemoved('42')),
      expect: () => [
        ready(changingFriendIds: {'42'}),
        ready(friends: const [alex]),
      ],
    );

    blocTest<FriendsBloc, FriendsState>(
      'blocking a student who sent a request takes the request away',
      build: build,
      seed: ready,
      act: (bloc) => bloc.add(const StudentBlocked('55')),
      expect: () => [
        ready(changingFriendIds: {'55'}),
        ready(requests: const []),
      ],
      verify: (_) {
        expect(repository.calls.first, 'blockStudent 55');
        expect(waiting.state.count, 0);
      },
    );

    blocTest<FriendsBloc, FriendsState>(
      'a block that fails says why, and keeps the row',
      build: build,
      seed: ready,
      setUp: () => repository.failNext['blockStudent'] =
          RefusedFailure(404, "We couldn't find that student."),
      act: (bloc) => bloc.add(const StudentBlocked('42')),
      expect: () => [
        ready(changingFriendIds: {'42'}),
        ready(errorMessage: "We couldn't find that student."),
      ],
    );
  });

  group('reporting', () {
    blocTest<FriendsBloc, FriendsState>(
      'sends the reason and the note, then says it was sent',
      build: build,
      seed: () => ready(reportStatus: ReportStatus.sent),
      act: (bloc) => bloc
        ..add(const ReportOpened())
        ..add(const StudentReported(
          friendId: '42',
          reason: ReportReason.bullying,
          note: 'Mean in class.',
        )),
      expect: () => [
        ready(),
        ready(reportStatus: ReportStatus.sending),
        ready(reportStatus: ReportStatus.sent),
      ],
      verify: (_) => expect(
          repository.calls, ['reportStudent 42 bullying Mean in class.']),
    );

    blocTest<FriendsBloc, FriendsState>(
      'a report that fails says why, and can be sent again',
      build: build,
      seed: ready,
      setUp: () => repository.failNext['reportStudent'] = RefusedFailure(
          429, "You've done that a lot today. Try again tomorrow."),
      act: (bloc) => bloc.add(const StudentReported(
        friendId: '42',
        reason: ReportReason.other,
        note: '',
      )),
      expect: () => [
        ready(reportStatus: ReportStatus.sending),
        ready(
          errorMessage: "You've done that a lot today. Try again tomorrow.",
        ),
      ],
    );
  });
}
