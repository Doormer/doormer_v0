import 'dart:convert';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:flutter/services.dart' show rootBundle;

class RegistrationLocalDataSource {
  /// Loads registration options from the local JSON asset.
  Future<Map<String, dynamic>> getRegistrationOptions() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/candidate_registration_options/candidate_registration_options.json',
      );
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (error, stackTrace) {
      AppLogger.error('Failed to load registration options', error: error, stackTrace: stackTrace);
      throw DatabaseFailure(
          'Failed to load registration options.');
    }
  }
}
