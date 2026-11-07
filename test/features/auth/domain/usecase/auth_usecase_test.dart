import 'package:doormer/src/features/auth/domain/repository/auth_repository.dart';
import 'package:doormer/src/features/auth/domain/usecase/auth_usecase.dart';
import 'package:doormer/src/shared/user/entity/user.dart';
import 'package:flutter_test/flutter_test.dart';

class _CredentialsRecordingRepository implements AuthRepository {
  String? email;
  String? password;

  @override
  Future<User> login({required String email, required String password}) async {
    this.email = email;
    this.password = password;
    return const User();
  }

  @override
  Future<User> signup({required String email, required String password}) async {
    this.email = email;
    this.password = password;
    return const User();
  }

  @override
  Future<User> signInWithGoogle(String idToken) => throw UnimplementedError();

  @override
  Future<void> verifyEmail({required String email, required String code}) =>
      throw UnimplementedError();

  @override
  Future<void> logout() => throw UnimplementedError();
}

void main() {
  group('Login', () {
    test('sends the email without the spaces around it', () async {
      final repository = _CredentialsRecordingRepository();

      await AuthUseCase(repository)
          .login(email: '  mia@example.com \n', password: 'levels123');

      expect(repository.email, 'mia@example.com');
    });

    test('sends the password exactly as typed, spaces included', () async {
      final repository = _CredentialsRecordingRepository();

      await AuthUseCase(repository)
          .login(email: 'mia@example.com', password: ' pass word ');

      expect(repository.password, ' pass word ');
    });
  });

  group('Signup', () {
    test('sends the email without the spaces around it', () async {
      final repository = _CredentialsRecordingRepository();

      await AuthUseCase(repository)
          .signup(email: '  newkid@example.com ', password: 'levels123');

      expect(repository.email, 'newkid@example.com');
    });

    test('sends the password exactly as typed, spaces included', () async {
      final repository = _CredentialsRecordingRepository();

      await AuthUseCase(repository)
          .signup(email: 'newkid@example.com', password: ' pass word ');

      expect(repository.password, ' pass word ');
    });
  });
}
