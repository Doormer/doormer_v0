import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/core/utils/invite_code_storage/in_memory_invite_code_storage.dart';
import 'package:doormer/src/features/profile/domain/entity/found_student.dart';
import 'package:doormer/src/features/profile/domain/entity/friend_profile.dart';
import 'package:doormer/src/features/profile/domain/entity/friend_request.dart';
import 'package:doormer/src/features/profile/domain/usecase/find_student_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/forget_invite_code_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/load_friend_profile_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/reset_friend_code_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/send_friend_request_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/unblock_student_usecase.dart';
import 'package:doormer/src/features/profile/presentation/bloc/add_friend_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_friends_repository.dart';

void main() {
  setUpAll(AppLogger.disable);

  late FakeFriendsRepository repository;
  late InMemoryInviteCodeStorage inviteCodes;

  setUp(() {
    repository = FakeFriendsRepository();
    inviteCodes = InMemoryInviteCodeStorage();
  });

  AddFriendBloc build() => AddFriendBloc(
        loadProfile: LoadFriendProfileUseCase(repository),
        findStudent: FindStudentUseCase(repository),
        sendRequest: SendFriendRequestUseCase(repository),
        unblockStudent: UnblockStudentUseCase(repository),
        resetCode: ResetFriendCodeUseCase(repository),
        forgetInviteCode: ForgetInviteCodeUseCase(inviteCodes),
      );

  const ready = AddFriendReady(friendCode: kaiCode);

  AddFriendReady found(
    FoundStudent student,
    String code, {
    FriendRequestVia via = FriendRequestVia.code,
    bool isActing = false,
    String? errorMessage,
  }) =>
      AddFriendReady(
        friendCode: kaiCode,
        found: student,
        foundCode: code,
        via: via,
        isActing: isActing,
        errorMessage: errorMessage,
      );

  group('opening', () {
    blocTest<AddFriendBloc, AddFriendState>(
      'from Profile, shows the student their code',
      build: build,
      act: (bloc) => bloc.add(const AddFriendStarted()),
      expect: () => [ready],
    );

    blocTest<AddFriendBloc, AddFriendState>(
      'from an invite link, forgets the kept code and checks it at once',
      build: build,
      setUp: () => inviteCodes.keep(ruaCode),
      act: (bloc) => bloc.add(const AddFriendStarted(inviteCode: ruaCode)),
      expect: () => [
        ready,
        const AddFriendReady(friendCode: kaiCode, isFinding: true),
        found(
          const FoundStudent(
              student: rua, relation: FriendRelation.requestReceived),
          ruaCode,
          via: FriendRequestVia.link,
        ),
      ],
      verify: (_) async => expect(await inviteCodes.read(), isNull),
    );

    blocTest<AddFriendBloc, AddFriendState>(
      'with no friend profile, asks for setup first, keeping the code to check',
      build: build,
      setUp: () => repository.profile = const FriendProfile(
        hasProfile: false,
        nickname: '',
        friendCode: '',
        friendsTurnedOff: false,
        waitingRequests: 0,
      ),
      act: (bloc) => bloc.add(const AddFriendStarted(inviteCode: ruaCode)),
      expect: () => [const AddFriendNeedsSetup(inviteCode: ruaCode)],
    );

    blocTest<AddFriendBloc, AddFriendState>(
      'with friends turned off, says so',
      build: build,
      setUp: () => repository.profile = const FriendProfile(
        hasProfile: true,
        nickname: 'Kai',
        friendCode: kaiCode,
        friendsTurnedOff: true,
        waitingRequests: 0,
      ),
      act: (bloc) => bloc.add(const AddFriendStarted()),
      expect: () => [const AddFriendTurnedOff()],
    );

    blocTest<AddFriendBloc, AddFriendState>(
      'a load that fails says why',
      build: build,
      setUp: () => repository.failNext['loadProfile'] =
          NetworkFailure("We couldn't load your friends."),
      act: (bloc) => bloc.add(const AddFriendStarted()),
      expect: () => [const AddFriendError("We couldn't load your friends.")],
    );
  });

  group('finding a code', () {
    for (final (relation, code, student) in [
      (FriendRelation.none, niaCode, nia),
      (FriendRelation.requestReceived, ruaCode, rua),
      (FriendRelation.friends, alexCode, alex),
      (FriendRelation.blockedByYou, tamaCode, tama),
      (FriendRelation.you, kaiCode, kai),
    ]) {
      blocTest<AddFriendBloc, AddFriendState>(
        'shows the owner of $code, and that the two are $relation',
        build: build,
        seed: () => ready,
        act: (bloc) => bloc.add(FriendCodeSubmitted(code)),
        expect: () => [
          const AddFriendReady(friendCode: kaiCode, isFinding: true),
          found(FoundStudent(student: student, relation: relation), code),
        ],
      );
    }

    blocTest<AddFriendBloc, AddFriendState>(
      'reads a typed code without regard to case, spaces or dashes',
      build: build,
      seed: () => ready,
      act: (bloc) => bloc.add(const FriendCodeSubmitted(' news-2345 ')),
      skip: 1,
      expect: () => [
        found(const FoundStudent(student: nia, relation: FriendRelation.none),
            niaCode),
      ],
      verify: (_) => expect(repository.calls, ['findStudent $niaCode']),
    );

    blocTest<AddFriendBloc, AddFriendState>(
      "a code that can't be anyone's is never looked up",
      build: build,
      seed: () => ready,
      act: (bloc) => bloc.add(const FriendCodeSubmitted('K7QM-2XP0')),
      expect: () => [
        const AddFriendReady(
          friendCode: kaiCode,
          findMessage: "We couldn't find that code. Check it and try again.",
        ),
      ],
      verify: (_) => expect(repository.calls, isEmpty),
    );

    blocTest<AddFriendBloc, AddFriendState>(
      'a code nobody has says so',
      build: build,
      seed: () => ready,
      act: (bloc) => bloc.add(const FriendCodeSubmitted('ZZZZ2222')),
      expect: () => [
        const AddFriendReady(friendCode: kaiCode, isFinding: true),
        const AddFriendReady(
          friendCode: kaiCode,
          findMessage: "We couldn't find that code. Check it and try again.",
        ),
      ],
    );
  });

  group('acting on the student found', () {
    blocTest<AddFriendBloc, AddFriendState>(
      'Send request sends it by code, then says it was sent',
      build: build,
      seed: () => found(
          const FoundStudent(student: nia, relation: FriendRelation.none),
          niaCode),
      act: (bloc) => bloc.add(const FriendRequestSent()),
      expect: () => [
        found(const FoundStudent(student: nia, relation: FriendRelation.none),
            niaCode,
            isActing: true),
        found(
            const FoundStudent(
                student: nia, relation: FriendRelation.requestSent),
            niaCode),
      ],
      verify: (_) => expect(repository.calls, ['sendRequest $niaCode code']),
    );

    blocTest<AddFriendBloc, AddFriendState>(
      'Accept sends a request back by link, which makes the two friends',
      build: build,
      seed: () => found(
        const FoundStudent(
            student: rua, relation: FriendRelation.requestReceived),
        ruaCode,
        via: FriendRequestVia.link,
      ),
      act: (bloc) => bloc.add(const FriendRequestSent()),
      skip: 1,
      expect: () => [
        found(
          const FoundStudent(student: rua, relation: FriendRelation.friends),
          ruaCode,
          via: FriendRequestVia.link,
        ),
      ],
      verify: (_) => expect(repository.calls, ['sendRequest $ruaCode link']),
    );

    blocTest<AddFriendBloc, AddFriendState>(
      'a request that fails says why',
      build: build,
      seed: () => found(
          const FoundStudent(student: nia, relation: FriendRelation.none),
          niaCode),
      setUp: () => repository.failNext['sendRequest'] = RefusedFailure(
          409, 'You have 100 friends. Remove one to add another.'),
      act: (bloc) => bloc.add(const FriendRequestSent()),
      skip: 1,
      expect: () => [
        found(
          const FoundStudent(student: nia, relation: FriendRelation.none),
          niaCode,
          errorMessage: 'You have 100 friends. Remove one to add another.',
        ),
      ],
    );

    blocTest<AddFriendBloc, AddFriendState>(
      'Unblock leaves the two unconnected',
      build: build,
      seed: () => found(
          const FoundStudent(
              student: tama, relation: FriendRelation.blockedByYou),
          tamaCode),
      act: (bloc) => bloc.add(const FoundStudentUnblocked()),
      skip: 1,
      expect: () => [
        found(const FoundStudent(student: tama, relation: FriendRelation.none),
            tamaCode),
      ],
      verify: (_) => expect(repository.calls, ['unblockStudent 66']),
    );
  });

  blocTest<AddFriendBloc, AddFriendState>(
    'Reset code shows the new code',
    build: build,
    seed: () => ready,
    act: (bloc) => bloc.add(const FriendCodeReset()),
    expect: () => [
      const AddFriendReady(friendCode: kaiCode, isResettingCode: true),
      AddFriendReady(friendCode: FakeFriendsRepository.newCodes.first),
    ],
  );
}
