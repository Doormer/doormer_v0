import 'package:flutter/foundation.dart';

import 'friend_request_row_params.dart';
import 'friend_row_params.dart';
import 'profile_header_params.dart';

/// What fills Profile above Sign out.
sealed class ProfileBodyParams {
  const ProfileBodyParams();
}

/// Friends are on their way.
class ProfileLoadingParams extends ProfileBodyParams {
  const ProfileLoadingParams();
}

/// Friends could not load.
class ProfileErrorParams extends ProfileBodyParams {
  final String message;
  final VoidCallback onRetry;

  const ProfileErrorParams({required this.message, required this.onRetry});
}

/// The student hasn't set up friends.
class ProfileNotSetUpParams extends ProfileBodyParams {
  final VoidCallback onSetUp;

  const ProfileNotSetUpParams({required this.onSetUp});
}

/// The team turned friends off for this account.
class ProfileTurnedOffParams extends ProfileBodyParams {
  final String message;

  const ProfileTurnedOffParams({required this.message});
}

/// The student's friend profile, requests and friends.
class ProfileFriendsParams extends ProfileBodyParams {
  final ProfileHeaderParams header;
  final VoidCallback onAddFriend;

  /// None when no request is waiting.
  final List<FriendRequestRowParams> requests;

  final List<FriendRowParams> friends;
  final VoidCallback onOpenBlocked;

  const ProfileFriendsParams({
    required this.header,
    required this.onAddFriend,
    required this.requests,
    required this.friends,
    required this.onOpenBlocked,
  });
}
