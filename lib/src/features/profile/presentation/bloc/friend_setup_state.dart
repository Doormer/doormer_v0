part of 'friend_setup_bloc.dart';

sealed class FriendSetupState extends Equatable {
  const FriendSetupState();

  /// The student has no friend profile yet. Null until their profile has
  /// loaded, since until then setup can't be told from Edit. Once known, it
  /// stays on every state after.
  bool? get isFirstTime;

  @override
  List<Object?> get props => const [];
}

class FriendSetupLoading extends FriendSetupState {
  /// Known when Try again loads again after the profile has loaded.
  @override
  final bool? isFirstTime;

  const FriendSetupLoading({this.isFirstTime});

  @override
  List<Object?> get props => [isFirstTime];
}

/// The profile or the cards could not load.
class FriendSetupError extends FriendSetupState {
  final String message;

  /// Known when the profile has loaded before, as when only the cards failed.
  @override
  final bool? isFirstTime;

  const FriendSetupError(this.message, {this.isFirstTime});

  @override
  List<Object?> get props => [message, isFirstTime];
}

class FriendSetupReady extends FriendSetupState {
  @override
  final bool isFirstTime;

  /// As typed.
  final String nickname;

  /// Null for the first letter.
  final CardPicture? picture;

  /// One per card the student owns. None before their first card.
  final List<PictureChoice> choices;

  /// Why the nickname can't be saved, in the API's words. Cleared when the
  /// student types.
  final String? nicknameProblem;

  final bool isSaving;

  /// Set once when saving fails for another reason, so the page can say
  /// why. Cleared by the next change of state.
  final String? errorMessage;

  const FriendSetupReady({
    required this.isFirstTime,
    required this.nickname,
    this.picture,
    required this.choices,
    this.nicknameProblem,
    this.isSaving = false,
    this.errorMessage,
  });

  /// [picture] replaces the picture only with [clearPicture], since null
  /// means the first letter.
  FriendSetupReady copyWith({
    String? nickname,
    CardPicture? picture,
    bool clearPicture = false,
    String? nicknameProblem,
    bool? isSaving,
    String? errorMessage,
  }) {
    return FriendSetupReady(
      isFirstTime: isFirstTime,
      nickname: nickname ?? this.nickname,
      picture: clearPicture ? picture : (picture ?? this.picture),
      choices: choices,
      nicknameProblem: nicknameProblem,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isFirstTime,
        nickname,
        picture,
        choices,
        nicknameProblem,
        isSaving,
        errorMessage,
      ];
}

/// Saved. The page moves on.
class FriendSetupSaved extends FriendSetupState {
  @override
  final bool isFirstTime;

  const FriendSetupSaved({required this.isFirstTime});

  @override
  List<Object?> get props => [isFirstTime];
}
