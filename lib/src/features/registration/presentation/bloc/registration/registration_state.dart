part of 'registration_bloc.dart';

abstract class RegistrationState extends Equatable {
  const RegistrationState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any registration attempt.
class RegistrationInitial extends RegistrationState {}

/// State while registration is in progress.
class RegistrationLoading extends RegistrationState {}

/// State when registration is successful.
class RegistrationSuccess extends RegistrationState {}

/// State when registration fails.
class RegistrationError extends RegistrationState {
  final String errorMessage;

  const RegistrationError({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

/// State while loading registration options JSON.
class RegistrationOptionsLoading extends RegistrationState {}

/// State when registration options JSON has been successfully loaded.
class RegistrationOptionsLoaded extends RegistrationState {
  final Map<String, dynamic> options;

  const RegistrationOptionsLoaded({required this.options});

  @override
  List<Object?> get props => [options];
}

/// State when loading registration options JSON fails.
class RegistrationOptionsError extends RegistrationState {
  final String errorMessage;

  const RegistrationOptionsError({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
