part of 'registration_bloc.dart';

/// Registration events
abstract class RegistrationEvent extends Equatable {
  const RegistrationEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered to register a candidate.
class RegisterCandidateEvent extends RegistrationEvent {
  final CandidateDetails candidateDetails;
  final Uint8List cvBytes;
  final String cvFileName;
  final CandidatePreference candidatePreference;

  const RegisterCandidateEvent({
    required this.candidateDetails,
    required this.cvBytes,
    required this.cvFileName,
    required this.candidatePreference,
  });

  @override
  List<Object?> get props =>
      [candidateDetails, cvBytes, cvFileName, candidatePreference];
}

/// Event triggered to load the registration options JSON.
class LoadRegistrationOptionsEvent extends RegistrationEvent {
  const LoadRegistrationOptionsEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered when user uploads cv
class UpdateCVEvent extends RegistrationEvent {
  final Uint8List cvBytes;
  final String cvFileName;

  const UpdateCVEvent({
    required this.cvBytes,
    required this.cvFileName,
  });

  @override
  List<Object?> get props => [cvBytes, cvFileName];
}
