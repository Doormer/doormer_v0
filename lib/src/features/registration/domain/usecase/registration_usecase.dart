import 'dart:typed_data';
import 'package:doormer/src/core/errors/failure.dart';
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
    // Validate the CV file extension (only PDF allowed).
    final allowedExtensions = ['pdf'];
    final fileExtension = cvFileName.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(fileExtension)) {
      throw ValidationFailure(
          "Invalid file format. Only PDF files are allowed.");
    }

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
  }
}

/// Use case for retrieving registration options JSON data.
class GetRegistrationOptions {
  final RegistrationRepository repository;

  GetRegistrationOptions(this.repository);

  Future<Map<String, dynamic>> call() async {
    return await repository.getRegistrationOptions();
  }
}
