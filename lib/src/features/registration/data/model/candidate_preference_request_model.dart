import 'package:doormer/src/features/registration/domain/entity/candidate_preference.dart';

class CandidatePreferenceRequestModel {
  final List<String> role;
  final List<String> industry;
  final List<String> companySize;
  final List<String> expectation;
  final List<String> culture;

  CandidatePreferenceRequestModel({
    required this.role,
    required this.industry,
    required this.companySize,
    required this.expectation,
    required this.culture,
  });

  /// Converts a [CandidatePreference] entity into a [CandidatePreferenceRequestModel].
  factory CandidatePreferenceRequestModel.fromEntity(
      CandidatePreference entity) {
    return CandidatePreferenceRequestModel(
      role: entity.role,
      industry: entity.industry,
      companySize: entity.companySize,
      expectation: entity.expectation,
      culture: entity.culture,
    );
  }

  /// Converts this model into a [CandidatePreference] entity.
  CandidatePreference toEntity() {
    return CandidatePreference(
      role: role,
      industry: industry,
      companySize: companySize,
      expectation: expectation,
      culture: culture,
    );
  }

  /// Creates a [CandidatePreferenceRequestModel] from a JSON object.
  factory CandidatePreferenceRequestModel.fromJson(Map<String, dynamic> json) {
    return CandidatePreferenceRequestModel(
      role: List<String>.from(json['role'] ?? []),
      industry: List<String>.from(json['industry'] ?? []),
      companySize: List<String>.from(json['companySize'] ?? []),
      expectation: List<String>.from(json['expectation'] ?? []),
      culture: List<String>.from(json['culture'] ?? []),
    );
  }

  /// Converts this model to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'industry': industry,
      'companySize': companySize,
      'expectation': expectation,
      'culture': culture,
    };
  }
}
