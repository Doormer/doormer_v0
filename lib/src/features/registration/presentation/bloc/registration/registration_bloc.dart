import 'dart:typed_data';
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
      // Execute the use case that concurrently uploads files and registers candidate details.
      await registrationUseCase.registerCandidate(
        candidateDetails: event.candidateDetails,
        cvBytes: event.cvBytes,
        cvFileName: event.cvFileName,
        candidatePreference: event.candidatePreference,
      );
      emit(RegistrationSuccess());
    } catch (error) {
      emit(RegistrationFailure(errorMessage: error.toString()));
    }
  }

  Future<void> _onLoadRegistrationOptions(LoadRegistrationOptionsEvent event,
      Emitter<RegistrationState> emit) async {
    emit(RegistrationOptionsLoading());
    try {
      final options = await registrationUseCase.getRegistrationOptions.call();
      emit(RegistrationOptionsLoaded(options: options));
    } catch (error) {
      emit(RegistrationOptionsFailure(errorMessage: error.toString()));
    }
  }
}
