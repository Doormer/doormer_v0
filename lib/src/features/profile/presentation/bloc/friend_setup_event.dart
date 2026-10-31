part of 'friend_setup_bloc.dart';

sealed class FriendSetupEvent extends Equatable {
  const FriendSetupEvent();

  @override
  List<Object?> get props => const [];
}

/// Setup opened.
class FriendSetupStarted extends FriendSetupEvent {
  const FriendSetupStarted();
}

/// The student tapped Try again.
class FriendSetupRetried extends FriendSetupEvent {
  const FriendSetupRetried();
}

class NicknameChanged extends FriendSetupEvent {
  final String nickname;

  const NicknameChanged(this.nickname);

  @override
  List<Object?> get props => [nickname];
}

/// The student picked a card, or the first letter when [picture] is null.
class PictureChosen extends FriendSetupEvent {
  final CardPicture? picture;

  const PictureChosen(this.picture);

  @override
  List<Object?> get props => [picture];
}

/// The student tapped Done.
class FriendSetupDone extends FriendSetupEvent {
  const FriendSetupDone();
}
