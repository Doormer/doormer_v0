import 'dart:typed_data';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/registration/domain/entity/candidate_details.dart';
import 'package:doormer/src/features/registration/domain/entity/candidate_preference.dart';
import 'package:doormer/src/features/registration/domain/usecase/registration_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'registration_event.dart';
part 'registration_state.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  final RegistrationUseCase registrationUseCase;

  RegistrationBloc({
    required this.registrationUseCase,
  }) : super(RegistrationInitial()) {
    on<RegisterCandidateEvent>(_onRegisterCandidate);
    on<LoadRegistrationOptionsEvent>(_onLoadRegistrationOptions);
  }

  Future<void> _onRegisterCandidate(
      RegisterCandidateEvent event, Emitter<RegistrationState> emit) async {
    emit(RegistrationLoading());
    try {
      AppLogger.info(event.candidatePreference.companySize.toString());
      // Execute the use case that concurrently uploads files and registers candidate details.
      await registrationUseCase.registerCandidate(
        candidateDetails: event.candidateDetails,
        cvBytes: event.cvBytes,
        cvFileName: event.cvFileName,
        candidatePreference: event.candidatePreference,
      );
      emit(RegistrationSuccess());
    } on Failure catch (f, stackTrace) {
      emit(RegistrationFailure(errorMessage: f.message));
      AppLogger.error('Registration failed', error: f, stackTrace: stackTrace);
    } catch (error, stackTrace) {
      emit(RegistrationFailure(errorMessage: 'An unexpected error occurred'));
      AppLogger.error('Registration unexpected error',
          error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _onLoadRegistrationOptions(LoadRegistrationOptionsEvent event,
      Emitter<RegistrationState> emit) async {
    emit(RegistrationOptionsLoading());
    try {
      final options = await registrationUseCase.getRegistrationOptions.call();
      emit(RegistrationOptionsLoaded(options: options));
    } on Failure catch (f, stackTrace) {
      emit(RegistrationOptionsFailure(errorMessage: f.message));
      AppLogger.error('Load registration options failed',
          error: f, stackTrace: stackTrace);
    } catch (error, stackTrace) {
      emit(RegistrationOptionsFailure(
          errorMessage: 'An unexpected error occurred'));
      AppLogger.error('Load registration options unexpected error',
          error: error, stackTrace: stackTrace);
    }
  }
}
