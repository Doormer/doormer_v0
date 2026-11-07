import 'package:doormer/src/features/auth/utils/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthValidators.validateEmail', () {
    test('accepts an email with spaces or a line break around it', () {
      expect(AuthValidators.validateEmail('  mia@example.com  '), isNull);
      expect(AuthValidators.validateEmail('mia@example.com\n'), isNull);
    });

    test('asks for an email when the field holds only spaces', () {
      expect(AuthValidators.validateEmail('   '), 'Email is required');
    });

    test('still rejects a space inside the email', () {
      expect(
        AuthValidators.validateEmail('mia @example.com'),
        'Enter a valid email address',
      );
    });
  });
}
