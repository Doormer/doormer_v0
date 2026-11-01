import 'package:doormer/src/features/questions/presentation/mapper/question_sharing_presenter.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:flutter_test/flutter_test.dart';

List<FriendSummary> _friends(List<String> nicknames) => [
      for (final (index, nickname) in nicknames.indexed)
        FriendSummary(friendId: '$index', nickname: nickname),
    ];

void main() {
  group('sharedWithLabel', () {
    for (final (nicknames, label) in [
      (<String>[], ''),
      (['Sam'], 'Shared with Sam'),
      (['Sam', 'Alex'], 'Shared with Sam, Alex'),
      (['Sam', 'Alex', 'Kate'], 'Shared with Sam, Alex, Kate'),
      (
        ['Sam', 'Alex', 'Kate', 'Rua'],
        'Shared with Sam, Alex, Kate and 1 more'
      ),
      (
        ['Sam', 'Alex', 'Kate', 'Rua', 'Nia'],
        'Shared with Sam, Alex, Kate and 2 more'
      ),
    ]) {
      test('${nicknames.length} friends: "$label"', () {
        expect(sharedWithLabel(_friends(nicknames)), label);
      });
    }
  });
}
