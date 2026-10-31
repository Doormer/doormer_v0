import 'package:doormer/src/shared/friends/entity/card_picture.dart';
import 'package:equatable/equatable.dart';

/// The student's own friend profile: what friends see of them, and the code
/// that lets another student find them.
class FriendProfile extends Equatable {
  /// False until the student finishes setup. Until then [nickname] and
  /// [friendCode] are empty, [picture] is null and [waitingRequests] is 0.
  final bool hasProfile;

  final String nickname;

  /// Null until the student picks a card. Friends then see the nickname's
  /// first letter.
  final CardPicture? picture;

  /// 8 characters with no dash, such as `K7QM2XPA`. The app adds the dash
  /// when it shows one.
  final String friendCode;

  /// The team turned friends off for this account.
  final bool friendsTurnedOff;

  final int waitingRequests;

  const FriendProfile({
    required this.hasProfile,
    required this.nickname,
    this.picture,
    required this.friendCode,
    required this.friendsTurnedOff,
    required this.waitingRequests,
  });

  @override
  List<Object?> get props => [
        hasProfile,
        nickname,
        picture,
        friendCode,
        friendsTurnedOff,
        waitingRequests,
      ];
}
