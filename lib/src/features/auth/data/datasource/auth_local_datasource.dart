import 'dart:convert';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/auth/data/model/login_response_model.dart';
import 'package:flutter/services.dart';

class AuthLocalDataSource {
  Future<LoginResponseModel> signup(String email, String password) async {
    final mockData = await _loadMockData();

    if (mockData["user_info"]["email"] == email) {
      throw AuthFailure("User already exists.");
    }

    return LoginResponseModel.fromJson(mockData);
  }

  Future<LoginResponseModel> login(String email, String password) async {
    final mockData = await _loadMockData();

    if (mockData["user_info"]["email"] != email || password != "password123") {
      throw AuthFailure("Invalid email or password.");
    }

    return LoginResponseModel.fromJson(mockData);
  }

  Future<void> verifyEmail(String email, String code) async {
    if (code != "123456") {
      throw AuthFailure("Invalid verification code.");
    }
  }

  Future<String> getGoogleIdToken() async {
    return "mock-google-id-token";
  }

  Future<LoginResponseModel> exchangeGoogleIdTokenForTokens(
      String googleIdToken) async {
    final mockData = await _loadMockData();

    if (googleIdToken != "mock-google-id-token") {
      throw AuthFailure("Invalid Google ID token.");
    }

    return LoginResponseModel.fromJson(mockData);
  }

  Future<Map<String, dynamic>> _loadMockData() async {
    try {
      final mockJson =
          await rootBundle.loadString('assets/mock/mock_login_response.json');
      return json.decode(mockJson);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load auth mock data',
          error: e, stackTrace: stackTrace);
      throw DatabaseFailure('Something went wrong. Please try again.');
    }
  }
}
