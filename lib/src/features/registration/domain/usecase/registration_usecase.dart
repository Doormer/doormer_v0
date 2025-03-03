import 'dart:typed_data';
import 'package:doormer/src/features/registration/domain/entity/candidate_details.dart';
import 'package:doormer/src/features/registration/domain/entity/candidate_preference.dart';
import 'package:doormer/src/features/registration/domain/repository/registration_repository.dart';

/// RegistrationUseCase wraps both [RegisterCandidate] and [GetRegistrationOptions] use cases.
class RegistrationUseCase {
  final RegisterCandidate registerCandidate;
  final GetRegistrationOptions getRegistrationOptions;

  RegistrationUseCase(RegistrationRepository registrationRepository)
      : registerCandidate = RegisterCandidate(registrationRepository),
        getRegistrationOptions = GetRegistrationOptions(registrationRepository);
}

/// Use case for candidate registration.
/// It first concurrently uploads the CV and candidate preference.
/// Only when these uploads succeed, it calls the candidate registration API.
class RegisterCandidate {
  final RegistrationRepository repository;

  RegisterCandidate(this.repository);

  Future<void> call({
    required CandidateDetails candidateDetails,
    required Uint8List cvBytes,
    required String cvFileName,
    required CandidatePreference candidatePreference,
  }) async {
    // Validate the CV file extension (only PDF allowed) based on the file name.
    final allowedExtensions = ['pdf'];
    final fileExtension = cvFileName.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(fileExtension)) {
      throw Exception(
          "Invalid file format. Only PDF or DOCX files are allowed.");
    }

    try {
      // Generate a file name for candidate preference based on candidateDetails.
      final preferenceFileName =
          "${candidateDetails.firstName}_${candidateDetails.lastName}.json";

      // Step 1: Concurrently upload the CV and candidate preference.
      await Future.wait([
        repository.uploadCV(cvBytes, cvFileName),
        repository.uploadCandidatePreference(
            candidatePreference, preferenceFileName),
      ]);

      // Step 2: Register candidate details after successful file uploads.
      await repository.registerCandidateDetails(candidateDetails);
    } catch (error) {
      // Handle errors appropriately.
      throw Exception("Registration failed: $error");
    }
  }
}

/// Use case for retrieving registration options JSON data.
class GetRegistrationOptions {
  final RegistrationRepository repository;

  GetRegistrationOptions(this.repository);

  /// Retrieves the registration options from the repository.
  Future<Map<String, dynamic>> call() async {
    try {
      final options = await repository.getRegistrationOptions();
      return options;
    } catch (error) {
      throw Exception("Failed to get registration options: $error");
    }
  }
}
