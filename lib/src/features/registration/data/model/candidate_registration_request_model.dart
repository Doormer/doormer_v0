// TODO: Use JsonSerializable when finalized

import 'package:doormer/src/features/registration/domain/entity/candidate_details.dart';

class CandidateRegistrationRequestModel {
  final String mobileNumber;
  final String firstName;
  final String lastName;

  CandidateRegistrationRequestModel({
    required this.mobileNumber,
    required this.firstName,
    required this.lastName,
  });

  /// Creates a CandidateRegistrationRequestModel from a CandidateDetails entity.
  factory CandidateRegistrationRequestModel.fromEntity(
      CandidateDetails details) {
    return CandidateRegistrationRequestModel(
      mobileNumber: details.mobileNumber,
      firstName: details.firstName,
      lastName: details.lastName,
    );
  }

  /// Converts this model into a CandidateDetails entity.
  CandidateDetails toEntity() {
    return CandidateDetails(
      mobileNumber: mobileNumber,
      firstName: firstName,
      lastName: lastName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "mobile_number": mobileNumber,
      "first_name": firstName,
      "last_name": lastName,
    };
  }
}
