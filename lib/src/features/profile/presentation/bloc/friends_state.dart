part of 'friends_bloc.dart';

sealed class FriendsState extends Equatable {
  const FriendsState();

  @override
  List<Object?> get props => const [];
}

/// The first read.
class FriendsLoading extends FriendsState {
  const FriendsLoading();
}

/// The first read failed. Sign out still works.
class FriendsError extends FriendsState {
  final String message;

  const FriendsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// The student hasn't set up friends: Profile offers only Set up friends and
/// Sign out.
class FriendsNotSetUp extends FriendsState {
  const FriendsNotSetUp();
}

/// The team turned friends off for this account.
class FriendsTurnedOff extends FriendsState {
  const FriendsTurnedOff();
}

/// How the report sheet's report is going.
enum ReportStatus { unsent, sending, sent }

class FriendsReady extends FriendsState {
  final FriendProfile profile;

  /// Newest first.
  final List<FriendRequest> requests;

  /// By nickname, ignoring case.
  final List<FriendSummary> friends;

  /// Requests with an Accept or Decline on its way.
  final Set<String> answeringRequestIds;

  /// Students with a Remove or Block on its way.
  final Set<String> changingFriendIds;

  final ReportStatus reportStatus;

  /// Set once when an action fails, so the page can say why. Cleared by the
  /// next change of state.
  final String? errorMessage;

  const FriendsReady({
    required this.profile,
    required this.requests,
    required this.friends,
    this.answeringRequestIds = const {},
    this.changingFriendIds = const {},
    this.reportStatus = ReportStatus.unsent,
    this.errorMessage,
  });

  FriendsReady copyWith({
    Set<String>? answeringRequestIds,
    Set<String>? changingFriendIds,
    ReportStatus? reportStatus,
    String? errorMessage,
  }) {
    return FriendsReady(
      profile: profile,
      requests: requests,
      friends: friends,
      answeringRequestIds: answeringRequestIds ?? this.answeringRequestIds,
      changingFriendIds: changingFriendIds ?? this.changingFriendIds,
      reportStatus: reportStatus ?? this.reportStatus,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        profile,
        requests,
        friends,
        answeringRequestIds,
        changingFriendIds,
        reportStatus,
        errorMessage,
      ];
}
