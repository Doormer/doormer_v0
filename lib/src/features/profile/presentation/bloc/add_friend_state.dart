part of 'add_friend_bloc.dart';

sealed class AddFriendState extends Equatable {
  const AddFriendState();

  @override
  List<Object?> get props => const [];
}

class AddFriendLoading extends AddFriendState {
  const AddFriendLoading();
}

/// The student's own profile could not load.
class AddFriendError extends AddFriendState {
  final String message;

  const AddFriendError(this.message);

  @override
  List<Object?> get props => [message];
}

/// The student has no friend profile: setup comes first.
class AddFriendNeedsSetup extends AddFriendState {
  /// The invite's code, to check once setup is done.
  final String? inviteCode;

  const AddFriendNeedsSetup({this.inviteCode});

  @override
  List<Object?> get props => [inviteCode];
}

/// The team turned friends off for this account.
class AddFriendTurnedOff extends AddFriendState {
  const AddFriendTurnedOff();
}

class AddFriendReady extends AddFriendState {
  /// The student's own, with no dash.
  final String friendCode;

  final bool isResettingCode;
  final bool isFinding;

  /// The owner of the last code found. Null before a find, and when it
  /// found no one.
  final FoundStudent? found;

  /// The code [found] was found by, with no dash.
  final String? foundCode;

  /// How [foundCode] reached the student: typed, or from an invite link.
  final FriendRequestVia via;

  /// Why the last find found no one.
  final String? findMessage;

  /// A Send request, Accept or Unblock is on its way.
  final bool isActing;

  /// Set once when an action fails, so the page can say why. Cleared by the
  /// next change of state.
  final String? errorMessage;

  const AddFriendReady({
    required this.friendCode,
    this.isResettingCode = false,
    this.isFinding = false,
    this.found,
    this.foundCode,
    this.via = FriendRequestVia.code,
    this.findMessage,
    this.isActing = false,
    this.errorMessage,
  });

  /// [found] and [foundCode] replace the ones shown only when given.
  AddFriendReady copyWith({
    String? friendCode,
    bool? isResettingCode,
    bool? isFinding,
    FoundStudent? found,
    String? foundCode,
    FriendRequestVia? via,
    bool? isActing,
    String? errorMessage,
  }) {
    return AddFriendReady(
      friendCode: friendCode ?? this.friendCode,
      isResettingCode: isResettingCode ?? this.isResettingCode,
      isFinding: isFinding ?? this.isFinding,
      found: found ?? this.found,
      foundCode: foundCode ?? this.foundCode,
      via: via ?? this.via,
      findMessage: findMessage,
      isActing: isActing ?? this.isActing,
      errorMessage: errorMessage,
    );
  }

  /// No one found, and why: [message], or nothing while a find is on its
  /// way.
  AddFriendReady withNoOneFound(String? message) => AddFriendReady(
        friendCode: friendCode,
        isResettingCode: isResettingCode,
        via: via,
        findMessage: message,
        isActing: isActing,
      );

  @override
  List<Object?> get props => [
        friendCode,
        isResettingCode,
        isFinding,
        found,
        foundCode,
        via,
        findMessage,
        isActing,
        errorMessage,
      ];
}
