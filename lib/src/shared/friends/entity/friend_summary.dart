import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:equatable/equatable.dart';

import 'card_picture.dart';

/// How one student appears to another: a nickname, a picture and, to
/// friends, a level. Never a real name or an email.
class FriendSummary extends Equatable {
  /// The student's ID. Every friends route checks the relationship, so
  /// knowing it gains nothing.
  final String friendId;

  final String nickname;

  /// Null until the student picks a card, or when the card has left the
  /// deck catalog. Friends then see the nickname's first letter.
  final CardPicture? picture;

  /// Null below level 1, and wherever the API shows no level: finding a
  /// code, requests, Blocked, and a friend's decks and cards. Only friends
  /// see a level, in their friends list.
  final Level? level;

  const FriendSummary({
    required this.friendId,
    required this.nickname,
    this.picture,
    this.level,
  });

  @override
  List<Object?> get props => [friendId, nickname, picture, level];
}
