import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_friends_to_share_with_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/share_question_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/stop_sharing_question_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/share_question_bloc.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_question_sharing_repository.dart';

void main() {
  setUpAll(AppLogger.disable);

  late FakeQuestionSharingRepository repository;

  setUp(() => repository = FakeQuestionSharingRepository());

  ShareQuestionBloc build() => ShareQuestionBloc(
        loadFriends: LoadFriendsToShareWithUseCase(repository),
        shareQuestion: ShareQuestionUseCase(repository),
        stopSharing: StopSharingQuestionUseCase(repository),
      );

  ShareQuestionState started({List<FriendSummary> sharedWith = const []}) =>
      ShareQuestionState(questionId: ownQuestionId, sharedWith: sharedWith);

  ShareQuestionState picking(
    Set<String> ticked, {
    List<FriendSummary> sharedWith = const [],
    bool isSending = false,
    String? errorMessage,
  }) =>
      ShareQuestionState(
        questionId: ownQuestionId,
        sharedWith: sharedWith,
        sheet: ShareSheetReady(
          friends: repository.friends,
          ticked: ticked,
          isSending: isSending,
        ),
        errorMessage: errorMessage,
      );

  blocTest<ShareQuestionBloc, ShareQuestionState>(
    'starts with whoever the question is already shared with',
    build: build,
    act: (bloc) => bloc.add(
      const ShareQuestionStarted(questionId: ownQuestionId, sharedWith: [sam]),
    ),
    expect: () => [
      started(sharedWith: [sam])
    ],
  );

  group('opening the sheet', () {
    blocTest<ShareQuestionBloc, ShareQuestionState>(
      'lists the friends, with none ticked',
      build: build,
      seed: started,
      act: (bloc) => bloc.add(const ShareSheetOpened()),
      expect: () => [
        started().copyWith(sheet: const ShareSheetLoading()),
        picking({}),
      ],
    );

    blocTest<ShareQuestionBloc, ShareQuestionState>(
      'with no friends, says how to add some',
      build: build,
      setUp: () => repository.friends = [],
      seed: started,
      act: (bloc) => bloc.add(const ShareSheetOpened()),
      skip: 1,
      expect: () => [
        started().copyWith(
          sheet: const ShareSheetUnavailable(
              'Add friends on Profile to share questions with them.'),
        ),
      ],
    );

    blocTest<ShareQuestionBloc, ShareQuestionState>(
      'before setup, says the same',
      build: build,
      setUp: () => repository.failNext['loadFriends'] = RefusedFailure(
          409, 'Add friends on Profile to share questions with them.'),
      seed: started,
      act: (bloc) => bloc.add(const ShareSheetOpened()),
      skip: 1,
      expect: () => [
        started().copyWith(
          sheet: const ShareSheetUnavailable(
              'Add friends on Profile to share questions with them.'),
        ),
      ],
    );

    blocTest<ShareQuestionBloc, ShareQuestionState>(
      'with friends turned off, says so',
      build: build,
      setUp: () => repository.failNext['loadFriends'] =
          RefusedFailure(403, 'Friends is turned off for your account.'),
      seed: started,
      act: (bloc) => bloc.add(const ShareSheetOpened()),
      skip: 1,
      expect: () => [
        started().copyWith(
          sheet: const ShareSheetUnavailable(
              'Friends is turned off for your account.'),
        ),
      ],
    );

    blocTest<ShareQuestionBloc, ShareQuestionState>(
      'friends that fail to load offer Try again',
      build: build,
      setUp: () => repository.failNext['loadFriends'] =
          NetworkFailure("We couldn't load your friends."),
      seed: started,
      act: (bloc) => bloc.add(const ShareSheetOpened()),
      skip: 1,
      expect: () => [
        started().copyWith(
          sheet: const ShareSheetError("We couldn't load your friends."),
        ),
      ],
    );
  });

  group('ticking', () {
    blocTest<ShareQuestionBloc, ShareQuestionState>(
      'ticks a friend, and unticks them',
      build: build,
      seed: () => picking({}),
      act: (bloc) => bloc
        ..add(const ShareFriendToggled('13'))
        ..add(const ShareFriendToggled('11'))
        ..add(const ShareFriendToggled('13')),
      expect: () => [
        picking({'13'}),
        picking({'13', '11'}),
        picking({'11'}),
      ],
    );

    blocTest<ShareQuestionBloc, ShareQuestionState>(
      'a friend it is already shared with stays as they are',
      build: build,
      seed: () => picking({}, sharedWith: [sam]),
      act: (bloc) => bloc.add(const ShareFriendToggled('7')),
      expect: () => const <ShareQuestionState>[],
    );

    blocTest<ShareQuestionBloc, ShareQuestionState>(
      'ticks 10 at most',
      build: build,
      setUp: () => repository.friends = [
        for (var id = 1; id <= 11; id++)
          FriendSummary(friendId: '$id', nickname: 'Friend $id'),
      ],
      seed: () => picking({for (var id = 1; id <= 10; id++) '$id'}),
      act: (bloc) => bloc.add(const ShareFriendToggled('11')),
      expect: () => const <ShareQuestionState>[],
      verify: (bloc) =>
          expect((bloc.state.sheet as ShareSheetReady).isFull, isTrue),
    );

    blocTest<ShareQuestionBloc, ShareQuestionState>(
      'once 10 are ticked, unticking one frees a place for another',
      build: build,
      setUp: () => repository.friends = [
        for (var id = 1; id <= 11; id++)
          FriendSummary(friendId: '$id', nickname: 'Friend $id'),
      ],
      seed: () => picking({for (var id = 1; id <= 10; id++) '$id'}),
      act: (bloc) => bloc
        ..add(const ShareFriendToggled('10'))
        ..add(const ShareFriendToggled('11')),
      expect: () => [
        picking({for (var id = 1; id <= 9; id++) '$id'}),
        picking({for (var id = 1; id <= 9; id++) '$id', '11'}),
      ],
    );
  });

  group('sending', () {
    blocTest<ShareQuestionBloc, ShareQuestionState>(
      'shares with the friends ticked, in the order listed, then closes',
      build: build,
      seed: () => picking({'13', '11'}),
      act: (bloc) => bloc.add(const ShareSent()),
      expect: () => [
        picking({'13', '11'}, isSending: true),
        const ShareQuestionState(
          questionId: ownQuestionId,
          sharedWith: [alex, kate],
          notice: ShareNotice.shared,
        ),
      ],
      verify: (_) => expect(repository.calls, ['share 501 11,13']),
    );

    blocTest<ShareQuestionBloc, ShareQuestionState>(
      'sends nothing with no one ticked',
      build: build,
      seed: () => picking({}),
      act: (bloc) => bloc.add(const ShareSent()),
      expect: () => const <ShareQuestionState>[],
      verify: (_) => expect(repository.calls, isEmpty),
    );

    blocTest<ShareQuestionBloc, ShareQuestionState>(
      'when a friend ticked has left, shares nothing, and lists the friends '
      'as they are now, still ticked',
      build: build,
      seed: () => picking({'13', '11'}),
      act: (bloc) {
        // Kate stopped being a friend after the sheet opened.
        repository.friends = [alex, sam];
        bloc.add(const ShareSent());
      },
      skip: 1,
      expect: () => [
        picking(
          {'11'},
          errorMessage:
              'Your friends list changed. Check the ticks and send again.',
        ),
      ],
      verify: (bloc) {
        expect(repository.calls, ['share 501 11,13', 'loadFriends']);
        expect(bloc.state.sharedWith, isEmpty);
      },
    );

    blocTest<ShareQuestionBloc, ShareQuestionState>(
      'a send that fails otherwise says why, and keeps the ticks',
      build: build,
      setUp: () => repository.failNext['share'] =
          ServerFailure("We couldn't share that question. Try again."),
      seed: () => picking({'13'}),
      act: (bloc) => bloc.add(const ShareSent()),
      skip: 1,
      expect: () => [
        picking(
          {'13'},
          errorMessage: "We couldn't share that question. Try again.",
        ),
      ],
    );

    blocTest<ShareQuestionBloc, ShareQuestionState>(
      'while sending, the ticks stay as they are, and Send sends nothing more',
      build: build,
      seed: () => picking({'11'}, isSending: true),
      act: (bloc) => bloc
        ..add(const ShareFriendToggled('13'))
        ..add(const ShareFriendToggled('11'))
        ..add(const ShareSent()),
      expect: () => const <ShareQuestionState>[],
      verify: (_) => expect(repository.calls, isEmpty),
    );

    blocTest<ShareQuestionBloc, ShareQuestionState>(
      'a sheet reopened while sending shows the send, and keeps its ticks '
      'when the send fails',
      build: build,
      setUp: () {
        repository.hold = Completer<void>();
        repository.failNext['share'] =
            ServerFailure("We couldn't share that question. Try again.");
      },
      seed: () => picking({'11'}),
      act: (bloc) async {
        // The student closes the sheet while it sends, opens it again and
        // ticks Kate, all before the send answers.
        bloc
          ..add(const ShareSent())
          ..add(const ShareSheetOpened())
          ..add(const ShareFriendToggled('13'));
        await Future<void>.delayed(Duration.zero);
        repository.hold!.complete();
      },
      expect: () => [
        picking({'11'}, isSending: true),
        picking(
          {'11'},
          errorMessage: "We couldn't share that question. Try again.",
        ),
      ],
      verify: (_) => expect(repository.calls, ['share 501 11']),
    );

    blocTest<ShareQuestionBloc, ShareQuestionState>(
      'a sheet reopened while sending closes once the send succeeds',
      build: build,
      setUp: () => repository.hold = Completer<void>(),
      seed: () => picking({'11'}),
      act: (bloc) async {
        bloc
          ..add(const ShareSent())
          ..add(const ShareSheetOpened());
        await Future<void>.delayed(Duration.zero);
        repository.hold!.complete();
      },
      expect: () => [
        picking({'11'}, isSending: true),
        const ShareQuestionState(
          questionId: ownQuestionId,
          sharedWith: [alex],
          notice: ShareNotice.shared,
        ),
      ],
      verify: (_) => expect(repository.calls, ['share 501 11']),
    );
  });

  group('stopping', () {
    blocTest<ShareQuestionBloc, ShareQuestionState>(
      'Stop sharing shares the question with no one',
      build: build,
      seed: () => started(sharedWith: [alex, sam]),
      act: (bloc) => bloc.add(const SharingStopped()),
      expect: () => [
        started(sharedWith: [alex, sam]).copyWith(isStopping: true),
        started().copyWith(notice: ShareNotice.stopped),
      ],
      verify: (_) => expect(repository.calls, ['stopSharing 501']),
    );

    blocTest<ShareQuestionBloc, ShareQuestionState>(
      'a stop that fails says why, and keeps who it is shared with',
      build: build,
      setUp: () => repository.failNext['stopSharing'] =
          NetworkFailure("We couldn't stop sharing. Try again."),
      seed: () => started(sharedWith: [sam]),
      act: (bloc) => bloc.add(const SharingStopped()),
      skip: 1,
      expect: () => [
        started(sharedWith: [sam]).copyWith(
          errorMessage: "We couldn't stop sharing. Try again.",
        ),
      ],
    );

    blocTest<ShareQuestionBloc, ShareQuestionState>(
      'Stop sharing does nothing while it is stopping',
      build: build,
      seed: () => started(sharedWith: [sam]).copyWith(isStopping: true),
      act: (bloc) => bloc.add(const SharingStopped()),
      expect: () => const <ShareQuestionState>[],
      verify: (_) => expect(repository.calls, isEmpty),
    );

    blocTest<ShareQuestionBloc, ShareQuestionState>(
      'Stop sharing does nothing for a question shared with no one',
      build: build,
      seed: started,
      act: (bloc) => bloc.add(const SharingStopped()),
      expect: () => const <ShareQuestionState>[],
      verify: (_) => expect(repository.calls, isEmpty),
    );
  });
}
