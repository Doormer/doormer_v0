import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class RegistrationLocalDataSource {
  /// Loads registration options from the local JSON asset.
  Future<Map<String, dynamic>> getRegistrationOptions() async {
    try {
      // Load the JSON file from the assets
      final String jsonString = await rootBundle.loadString(
        'assets/candidate_registration_options/candidate_registration_options.json',
      );
      // Decode the JSON string into a Map
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (error) {
      throw Exception('Failed to load registration options: $error');
    }
  }
}
