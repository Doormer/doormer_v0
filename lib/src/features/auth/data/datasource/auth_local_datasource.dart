import 'package:doormer/src/core/errors/failure.dart';

class AuthLocalDataSource {
  Future<void> verifyEmail(String email, String code) async {
    if (code != "123456") {
      throw AuthFailure("Invalid verification code.");
    }
  }
}
