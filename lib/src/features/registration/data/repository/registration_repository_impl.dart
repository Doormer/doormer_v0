import 'dart:convert';
import 'dart:typed_data';

import 'package:doormer/src/features/registration/data/datasource/registration_local_datasource.dart';
import 'package:doormer/src/features/registration/data/datasource/registration_remote_datasource.dart';
import 'package:doormer/src/features/registration/data/model/candidate_preference_request_model.dart';
import 'package:doormer/src/features/registration/data/model/candidate_registration_request_model.dart';
import 'package:doormer/src/features/registration/domain/entity/candidate_details.dart';
import 'package:doormer/src/features/registration/domain/entity/candidate_preference.dart';
import 'package:doormer/src/features/registration/domain/repository/registration_repository.dart';

/// An implementation of [RegistrationRepository] that uses remote and local data sources
/// for handling candidate registration, file uploads, and retrieving registration options.
class RegistrationRepositoryImpl implements RegistrationRepository {
  final RegistrationRemoteDataSource _remoteDataSource;
  final RegistrationLocalDataSource _localDataSource;

  RegistrationRepositoryImpl({
    required RegistrationRemoteDataSource remoteDataSource,
    required RegistrationLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  /// Registers candidate details by converting the entity to a DTO and calling the remote data source.
  @override
  Future<void> registerCandidateDetails(
      CandidateDetails candidateDetails) async {
    final candidateDetailsDTO =
        CandidateRegistrationRequestModel.fromEntity(candidateDetails);
    await _remoteDataSource.registerCandidate(candidateDetailsDTO);
  }

  /// Uploads the candidate's CV by first retrieving a SAS URL (using the file name as a query parameter)
  /// and then uploading the file bytes to that URL.
  @override
  Future<void> uploadCV(Uint8List cvBytes, String cvFileName) async {
    final sasUrl = await _remoteDataSource.getSasUploadUrl(cvFileName);
    // Introduce a short delay to allow for any clock skew issues.
    await Future.delayed(const Duration(seconds: 2));
    await _remoteDataSource.uploadFileToSasUrl(cvBytes, sasUrl);
  }

  /// Uploads candidate preferences by converting the entity to a DTO,
  /// retrieving a SAS URL with the provided file name, and then uploading the JSON data.
  @override
  Future<void> uploadCandidatePreference(
      CandidatePreference candidatePreference, String fileName) async {
    // Retrieve the SAS URL from the remote data source.
    final sasUrl = await _remoteDataSource.getSasUploadUrl(fileName);

    // Introduce a short delay to allow for any clock skew issues.
    await Future.delayed(const Duration(seconds: 2));
    // Convert the candidate preference entity to a DTO.
    final candidatePreferenceDTO =
        CandidatePreferenceRequestModel.fromEntity(candidatePreference);

    // Convert the DTO to a JSON string.
    final String jsonString = jsonEncode(candidatePreferenceDTO.toJson());
    // AppLogger.info(jsonString);

    // // Read the file contents as bytes.
    // final List<int> fileBytes = utf8.encode(jsonString);

    // Upload the file bytes using the data source.
    await _remoteDataSource.uploadJsonToSasUrl(jsonString, sasUrl);
  }

  /// Retrieves registration options from the local data source.
  @override
  Future<Map<String, dynamic>> getRegistrationOptions() async {
    return await _localDataSource.getRegistrationOptions();
  }
}
