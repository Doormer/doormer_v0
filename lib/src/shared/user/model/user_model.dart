import 'package:doormer/src/shared/user/entity/user.dart';

class UserModel {
  final int userRegistrationStatus;

  UserModel({required this.userRegistrationStatus});

  /// Creates a new UserModel instance from a JSON map.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userRegistrationStatus: json['user_registration_status'] as int,
    );
  }

  /// Converts the UserModel instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'user_registration_status': userRegistrationStatus,
    };
  }

  /// Converts the UserModel to a User entity.
  User toEntity() {
    return User(userRegistrationStatus: userRegistrationStatus);
  }
}
