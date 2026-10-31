import 'package:doormer/src/features/profile/utils/nickname_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tidy', () {
    test('removes the spaces at either end and makes each run one', () {
      expect(NicknameRules.tidy('  Sam   Lee  '), 'Sam Lee');
    });
  });

  group('problemWith', () {
    for (final nickname in [
      'Sam',
      'Cassie',
      'Āwhina',
      'Zoë_7',
      'mr.kai-2',
      'Kai1234',
      'Sixteen letters!'.replaceAll('!', 's'),
      'Łukasz', // Latin Extended-A
      'Ștefan', // Latin Extended-B, a comma below
      'Nguyễn', // Latin Extended Additional
    ]) {
      test('"$nickname" is fine', () {
        expect(NicknameRules.problemWith(nickname), isNull);
      });
    }

    test('3 to 16 characters, counted after tidying', () {
      expect(NicknameRules.problemWith('Al'), 'Use 3 to 16 characters.');
      expect(NicknameRules.problemWith('  Al  '), 'Use 3 to 16 characters.');
      expect(NicknameRules.problemWith('Sam'), isNull);
      expect(NicknameRules.problemWith('Abcdefghijklmnop'), isNull);
      expect(NicknameRules.problemWith('Abcdefghijklmnopq'),
          'Use 3 to 16 characters.');
      expect(NicknameRules.problemWith('Sam      Lee'), isNull,
          reason: 'the spaces between collapse to one');
    });

    test('a letter with a macron is one character', () {
      expect(NicknameRules.problemWith('Āaa'), isNull);
    });

    for (final nickname in [
      'sam@mail.com',
      'a/b/c',
      'Сэм',
      'Sam 😀',
      'K+K',
      // Lookalike letters, refused so a blocked word can't hide in them:
      'ｓａｍ', // fullwidth
      'S\u1D00m', // a small capital A
      'Sam\u1D57', // a superscript t
      '\u212Aiwi', // the Kelvin sign, which looks like K
      'Je\uFB00', // the ligature ff
    ]) {
      test('"$nickname" uses a character that is not allowed', () {
        expect(NicknameRules.problemWith(nickname),
            'Use letters, numbers, spaces, dots, dashes or underscores.');
      });
    }

    test('needs at least one letter', () {
      expect(NicknameRules.problemWith('1234'), 'Include at least one letter.');
      expect(NicknameRules.problemWith('._-'), 'Include at least one letter.');
    });

    test('allows 4 numbers but not 5', () {
      expect(NicknameRules.problemWith('Kai 1234'), isNull);
      expect(NicknameRules.problemWith('Kai 12345'),
          'Use no more than 4 numbers.');
      expect(NicknameRules.problemWith('1a2b3c4d5'),
          'Use no more than 4 numbers.');
    });

    test('checks length before anything else', () {
      expect(NicknameRules.problemWith('@@'), 'Use 3 to 16 characters.');
    });
  });
}
