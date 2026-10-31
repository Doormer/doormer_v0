import '../../domain/entity/found_student.dart';

/// What a found student's button does.
enum FoundStudentAction {
  sendRequest('Send request'),

  /// Sends a request back, which makes the two friends at once.
  accept('Accept'),

  viewCards('View cards'),
  unblock('Unblock');

  const FoundStudentAction(this.label);

  final String label;
}

/// What shows under a found student's nickname: a line saying how the two
/// are connected, and a button.
class FoundStudentContent {
  /// Null when there is no line.
  final String? status;

  /// Null when there is nothing to do.
  final FoundStudentAction? action;

  const FoundStudentContent({this.status, this.action});
}

/// The words and the button for each way the student and the code's owner
/// can be connected.
FoundStudentContent foundStudentContent(FriendRelation relation) =>
    switch (relation) {
      FriendRelation.none =>
        const FoundStudentContent(action: FoundStudentAction.sendRequest),
      FriendRelation.requestReceived =>
        const FoundStudentContent(action: FoundStudentAction.accept),
      FriendRelation.requestSent =>
        const FoundStudentContent(status: 'Request sent'),
      FriendRelation.friends => const FoundStudentContent(
          status: "You're friends",
          action: FoundStudentAction.viewCards,
        ),
      FriendRelation.blockedByYou => const FoundStudentContent(
          status: 'You blocked them',
          action: FoundStudentAction.unblock,
        ),
      FriendRelation.you =>
        const FoundStudentContent(status: "That's your code."),
    };
