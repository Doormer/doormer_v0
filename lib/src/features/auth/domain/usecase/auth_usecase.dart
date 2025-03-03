import 'package:doormer/src/features/auth/domain/repository/auth_repository.dart';
import 'package:doormer/src/shared/user/entity/user.dart';

class AuthUseCase {
  final Signup signup;
  final Login login;
  final SignInWithGoogle signInWithGoogle;
  final VerifyEmail verifyEmail;

  AuthUseCase(AuthRepository authRepository)
      : signup = Signup(authRepository),
        login = Login(authRepository),
        signInWithGoogle = SignInWithGoogle(authRepository),
        verifyEmail = VerifyEmail(authRepository);
}

class Signup {
  final AuthRepository authRepository;

  Signup(this.authRepository);

  Future<User> call({
    required String email,
    required String password,
  }) async {
    return await authRepository.signup(
      email: email,
      password: password,
    );
  }
}

class Login {
  final AuthRepository authRepository;

  Login(this.authRepository);

  Future<User> call({
    required String email,
    required String password,
  }) async {
    return await authRepository.login(email: email, password: password);
  }
}

class SignInWithGoogle {
  final AuthRepository authRepository;

  SignInWithGoogle(this.authRepository);

  Future<User> call(String idToken) async {
    return await authRepository.signInWithGoogle(idToken);
  }
}

class VerifyEmail {
  final AuthRepository authRepository;

  VerifyEmail(this.authRepository);

  Future<void> call({
    required String email,
    required String code,
  }) async {
    return await authRepository.verifyEmail(email: email, code: code);
  }
}
