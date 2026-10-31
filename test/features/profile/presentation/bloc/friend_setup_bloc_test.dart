import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/profile/domain/entity/friend_profile.dart';
import 'package:doormer/src/features/profile/domain/usecase/load_friend_profile_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/load_picture_choices_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/save_friend_profile_usecase.dart';
import 'package:doormer/src/features/profile/presentation/bloc/friend_setup_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_friends_repository.dart';

const _noProfile = FriendProfile(
  hasProfile: false,
  nickname: '',
  friendCode: '',
  friendsTurnedOff: false,
  waitingRequests: 0,
);

void main() {
  setUpAll(AppLogger.disable);

  late FakeFriendsRepository repository;

  setUp(() => repository = FakeFriendsRepository());

  FriendSetupBloc build() => FriendSetupBloc(
        loadProfile: LoadFriendProfileUseCase(repository),
        loadPictureChoices: LoadPictureChoicesUseCase(repository),
        saveProfile: SaveFriendProfileUseCase(repository),
      );

  FriendSetupReady firstTime({
    String nickname = '',
    String? nicknameProblem,
    bool isSaving = false,
    String? errorMessage,
  }) =>
      FriendSetupReady(
        isFirstTime: true,
        nickname: nickname,
        choices: repository.pictureChoices,
        nicknameProblem: nicknameProblem,
        isSaving: isSaving,
        errorMessage: errorMessage,
      );

  blocTest<FriendSetupBloc, FriendSetupState>(
    'the first time, starts empty, with the cards to pick from',
    build: build,
    setUp: () => repository.profile = _noProfile,
    act: (bloc) => bloc.add(const FriendSetupStarted()),
    expect: () => [firstTime()],
  );

  blocTest<FriendSetupBloc, FriendSetupState>(
    'later, starts from the saved nickname and picture',
    build: build,
    act: (bloc) => bloc.add(const FriendSetupStarted()),
    expect: () => [
      FriendSetupReady(
        isFirstTime: false,
        nickname: 'Kai',
        picture: gnomon,
        choices: repository.pictureChoices,
      ),
    ],
  );

  blocTest<FriendSetupBloc, FriendSetupState>(
    'a load that fails says why, and Try again loads with the spinner',
    build: build,
    setUp: () => repository.failNext['loadPictureChoices'] =
        NetworkFailure("We couldn't load your cards."),
    act: (bloc) async {
      bloc.add(const FriendSetupStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const FriendSetupRetried());
    },
    expect: () => [
      const FriendSetupError("We couldn't load your cards."),
      const FriendSetupLoading(),
      isA<FriendSetupReady>(),
    ],
  );

  blocTest<FriendSetupBloc, FriendSetupState>(
    'picks a card, then the first letter',
    build: build,
    seed: firstTime,
    act: (bloc) => bloc
      ..add(const PictureChosen(vernier))
      ..add(const PictureChosen(null)),
    expect: () => [
      FriendSetupReady(
        isFirstTime: true,
        nickname: '',
        picture: vernier,
        choices: repository.pictureChoices,
      ),
      firstTime(),
    ],
  );

  blocTest<FriendSetupBloc, FriendSetupState>(
    'Done with a nickname the API would refuse says why, and sends nothing',
    build: build,
    seed: () => firstTime(nickname: 'sam@mail'),
    act: (bloc) => bloc.add(const FriendSetupDone()),
    expect: () => [
      firstTime(
        nickname: 'sam@mail',
        nicknameProblem:
            'Use letters, numbers, spaces, dots, dashes or underscores.',
      ),
    ],
    verify: (_) => expect(repository.calls, isEmpty),
  );

  blocTest<FriendSetupBloc, FriendSetupState>(
    'typing clears the problem',
    build: build,
    seed: () =>
        firstTime(nickname: 'Al', nicknameProblem: 'Use 3 to 16 characters.'),
    act: (bloc) => bloc.add(const NicknameChanged('Alf')),
    expect: () => [firstTime(nickname: 'Alf')],
  );

  blocTest<FriendSetupBloc, FriendSetupState>(
    'Done saves the tidied nickname and the picture',
    build: build,
    seed: () => FriendSetupReady(
      isFirstTime: true,
      nickname: '  Rangi   Kai ',
      picture: vernier,
      choices: repository.pictureChoices,
    ),
    act: (bloc) => bloc.add(const FriendSetupDone()),
    expect: () => [
      FriendSetupReady(
        isFirstTime: true,
        nickname: '  Rangi   Kai ',
        picture: vernier,
        choices: repository.pictureChoices,
        isSaving: true,
      ),
      const FriendSetupSaved(),
    ],
    verify: (_) => expect(repository.calls, ['saveProfile Rangi Kai vernier']),
  );

  blocTest<FriendSetupBloc, FriendSetupState>(
    'a nickname on the word list is asked to change',
    build: build,
    seed: () => firstTime(nickname: 'Rude'),
    setUp: () => repository.failNext['saveProfile'] =
        RefusedFailure(422, 'Please pick a different nickname.'),
    act: (bloc) => bloc.add(const FriendSetupDone()),
    expect: () => [
      firstTime(nickname: 'Rude', isSaving: true),
      firstTime(
        nickname: 'Rude',
        nicknameProblem: 'Please pick a different nickname.',
      ),
    ],
  );

  blocTest<FriendSetupBloc, FriendSetupState>(
    'a save that fails for another reason says why',
    build: build,
    seed: () => firstTime(nickname: 'Rangi'),
    setUp: () => repository.failNext['saveProfile'] = NetworkFailure(
        "We couldn't save your nickname and picture. Try again."),
    act: (bloc) => bloc.add(const FriendSetupDone()),
    expect: () => [
      firstTime(nickname: 'Rangi', isSaving: true),
      firstTime(
        nickname: 'Rangi',
        errorMessage: "We couldn't save your nickname and picture. Try again.",
      ),
    ],
  );
}
