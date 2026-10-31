import 'package:doormer/src/features/profile/domain/entity/found_student.dart';
import 'package:doormer/src/features/profile/presentation/mapper/found_student_presenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (relation, status, button) in [
    (FriendRelation.none, null, 'Send request'),
    (FriendRelation.requestReceived, null, 'Accept'),
    (FriendRelation.requestSent, 'Request sent', null),
    (FriendRelation.friends, "You're friends", 'View cards'),
    (FriendRelation.blockedByYou, 'You blocked them', 'Unblock'),
    (FriendRelation.you, "That's your code.", null),
  ]) {
    test('$relation shows ${status ?? 'no line'} and ${button ?? 'no button'}',
        () {
      final content = foundStudentContent(relation);

      expect(content.status, status);
      expect(content.action?.label, button);
    });
  }
}
