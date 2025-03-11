import 'package:doormer/src/shared/user/model/user_model.dart';

class LoginResponseModel {
  final String accessToken;
  final String refreshToken;
  final UserModel? user;

  LoginResponseModel({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      user: json['user_info'] != null
          ? UserModel.fromJson(json['user_info'] as Map<String, dynamic>)
          : null,
    );
  }
}
