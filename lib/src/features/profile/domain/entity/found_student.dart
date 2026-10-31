import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:equatable/equatable.dart';

/// How the student who looked up a code is connected to the code's owner.
enum FriendRelation {
  none,

  /// A request to them is waiting, or they declined one less than 30 days
  /// ago. A decline looks the same as no answer.
  requestSent,

  /// They have a request to the student waiting.
  requestReceived,

  friends,
  blockedByYou,

  /// The code is the student's own.
  you,
}

/// The owner of a friend code, so the student can check it's the right
/// person, and how the two are connected.
class FoundStudent extends Equatable {
  final FriendSummary student;
  final FriendRelation relation;

  const FoundStudent({required this.student, required this.relation});

  @override
  List<Object?> get props => [student, relation];
}
