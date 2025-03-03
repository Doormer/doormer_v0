import 'dart:typed_data';

import 'package:doormer/src/features/registration/domain/entity/candidate_details.dart';
import 'package:doormer/src/features/registration/domain/entity/candidate_preference.dart';

/// Abstract repository for candidate registration.
abstract class RegistrationRepository {
  /// Registers candidate details and returns a candidate identifier.
  Future<void> registerCandidateDetails(CandidateDetails candidateDetails);

  /// Uploads the candidate's CV (PDF or DOCX) using the provided candidate identifier.
  Future<void> uploadCV(Uint8List cvBytes, String cvFileName);

  /// Uploads the candidate's preference (as JSON in the data layer) using the provided candidate identifier.
  Future<void> uploadCandidatePreference(
      CandidatePreference candidatePreference, String fileName);

  /// Retrieves the candidate registration options from the local JSON data.
  Future<Map<String, dynamic>> getRegistrationOptions();
}
