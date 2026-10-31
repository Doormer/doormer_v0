import 'package:doormer/src/features/profile/utils/friend_codes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a code is shown with a dash in the middle', () {
    expect(FriendCodes.display('K7QM2XPA'), 'K7QM-2XPA');
  });

  group('a typed code is read without regard to case, spaces or dashes', () {
    for (final typed in [
      'K7QM2XPA',
      'k7qm-2xpa',
      ' K7QM 2XPA ',
      'k7qm–2xpa',
      'K7-QM-2X-PA',
    ]) {
      test('"$typed"', () {
        expect(FriendCodes.normalise(typed), 'K7QM2XPA');
      });
    }
  });

  group('isWellFormed', () {
    test('8 characters from the alphabet', () {
      expect(FriendCodes.isWellFormed('K7QM2XPA'), isTrue);
    });

    test('too short or too long', () {
      expect(FriendCodes.isWellFormed('K7QM2XP'), isFalse);
      expect(FriendCodes.isWellFormed('K7QM2XPAB'), isFalse);
    });

    test('has none of 0, 1, I or O', () {
      for (final code in ['K7QM2XP0', 'K7QM2XP1', 'K7QM2XPI', 'K7QM2XPO']) {
        expect(FriendCodes.isWellFormed(code), isFalse, reason: code);
      }
    });
  });

  test("the invite link is the app's own address, /add/ and the code", () {
    expect(
      FriendCodes.inviteLink('K7QM2XPA',
          appAddress: Uri.parse('https://app.doormer.com/profile/add')),
      'https://app.doormer.com/add/K7QM2XPA',
    );
    expect(
      FriendCodes.inviteLink('K7QM2XPA',
          appAddress: Uri.parse('http://localhost:5052/profile/add')),
      'http://localhost:5052/add/K7QM2XPA',
    );
  });
}
