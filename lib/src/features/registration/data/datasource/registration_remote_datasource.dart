import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/registration/data/model/candidate_registration_request_model.dart';

class RegistrationRemoteDataSource {
  final Dio dio;

  RegistrationRemoteDataSource({required this.dio});

  /// Fetch a SAS Upload URL for the given file name
  Future<String> getSasUploadUrl(String fileName) async {
    try {
      final response = await dio.post(
        '/candidate/cv-upload',
        queryParameters: {'file_name': fileName},
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data["signed_upload_destination_url"];
      } else {
        throw Exception('Failed to retrieve SAS upload URL');
      }
    } catch (e) {
      AppLogger.error('Failed to get SAS URL: $e');
      throw Exception('Error fetching SAS upload URL: $e');
    }
  }

  /// Upload the file to Azure Blob Storage using the SAS URL (external call)
  Future<void> uploadFileToSasUrl(Uint8List fileBytes, String sasUrl) async {
    try {
      final response = await dio.put(
        sasUrl,
        data: fileBytes,
        options: Options(
          headers: {
            'x-ms-blob-type': 'BlockBlob',
            'Content-Type': 'application/pdf',
          },
          extra: {'skipAuth': true},
        ),
      );

      // Azure Blob Storage typically returns 201 (Created) for a successful PUT.
      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.info('File uploaded successfully');
      } else {
        AppLogger.error(
            'Upload failed with status ${response.statusCode}: ${response.data}');
        throw Exception(
            'Error uploading file: status code ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('File upload failed: $e');
      throw Exception('Error uploading file: $e');
    }
  }

  /// Upload the JSON data to Azure Blob Storage using the SAS URL (external call)
  Future<void> uploadJsonToSasUrl(String jsonString, String sasUrl) async {
    try {
      // Upload the file bytes using a PUT request.
      final response = await dio.put(
        sasUrl,
        data: jsonString,
        options: Options(
          headers: {
            'x-ms-blob-type': 'BlockBlob',
            'Content-Type': 'application/json',
          },
          extra: {'skipAuth': true},
        ),
      );

      // Azure Blob Storage typically returns 201 (Created) for a successful PUT.
      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.info('JSON file uploaded successfully');
      } else {
        AppLogger.error(
            'Upload failed with status ${response.statusCode}: ${response.data}');
        throw Exception(
            'Error uploading JSON file: status code ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('JSON file upload failed: $e');
      throw Exception('Error uploading JSON file: $e');
    }
  }

  /// Register a candidate (authenticated call)
  Future<void> registerCandidate(
      CandidateRegistrationRequestModel request) async {
    try {
      FormData formData = FormData.fromMap(request.toJson());
      await dio.post(
        '/candidate/register',
        data: formData,
      );
    } catch (e) {
      AppLogger.error('Candidate registration failed: $e');
      throw Exception('Error registering candidate: $e');
    }
  }
}
