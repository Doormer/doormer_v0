import 'package:equatable/equatable.dart';

import 'card_picture.dart';

/// How one student appears to another: a nickname and a picture, never a
/// real name or an email.
class FriendSummary extends Equatable {
  /// The student's ID. Every friends route checks the relationship, so
  /// knowing it gains nothing.
  final String friendId;

  final String nickname;

  /// Null until the student picks a card, or when the card has left the
  /// deck catalog. Friends then see the nickname's first letter.
  final CardPicture? picture;

  const FriendSummary({
    required this.friendId,
    required this.nickname,
    this.picture,
  });

  @override
  List<Object?> get props => [friendId, nickname, picture];
}
