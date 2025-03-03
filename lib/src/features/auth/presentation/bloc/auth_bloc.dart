import 'package:bloc/bloc.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/auth/domain/usecase/auth_usecase.dart';
import 'package:doormer/src/shared/sessions/bloc/global_session_bloc.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthUseCase authUseCase;
  final GlobalSessionBloc globalSessionBloc;

  // Constructor injects AuthUseCase and initializes the bloc with AuthInitial state
  AuthBloc({
    required this.authUseCase,
    required this.globalSessionBloc,
  }) : super(AuthInitial()) {
    // Registering event handlers for signup and login requests
    on<SignupRequested>(_onSignupRequested);
    on<LoginRequested>(_onLoginRequested);
    on<VerifyEmailRequested>(_onConfirmEmailRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
  }

  /// Handles the SignupRequested event
  Future<void> _onSignupRequested(
      SignupRequested event, Emitter<AuthState> emit) async {
    AppLogger.info('SignupRequested event received: email=${event.email}');

    // Emit loading state before performing signup
    emit(AuthLoading());
    AppLogger.debug('AuthLoading state emitted');

    try {
      // Call signup method on authUseCase and await result
      await authUseCase.signup(
        email: event.email,
        password: event.password,
      );

      // Dispatch SessionStarted to GlobalSessionBloc
      globalSessionBloc.add(SessionStarted());

      // Emit success state with user data upon successful signup
      emit(AuthSuccess());
      AppLogger.info('AuthSuccess state emitted.');
    } catch (e) {
      String errorMessage;

      // Check if the error is a Map and extract a message if available.
      if (e is Map) {
        // Try to extract the 'message' field if it exists.
        final dynamic msg = e['message'];
        AppLogger.error(msg);
        if (msg is String) {
          errorMessage = msg;
        } else {
          errorMessage = msg?.toString() ?? 'Signup failed';
        }
      } else {
        // Otherwise, assume it's already a string-like error.
        errorMessage = e.toString();
      }

      // Normalize the error message for the UI.
      if (errorMessage.contains("user is already registered")) {
        errorMessage = "User is already registered";
      } else {
        errorMessage = "Signup Failed";
      }

      emit(AuthFailure(errorMessage));
      AppLogger.error('AuthFailure state emitted with error $errorMessage');
    }
  }

  /// Handles the LoginRequested event
  Future<void> _onLoginRequested(
      LoginRequested event, Emitter<AuthState> emit) async {
    AppLogger.info('LoginRequested event received: email=${event.email}');

    // Emit loading state before performing login
    emit(AuthLoading());

    try {
      // Call login method on authUseCase and await result
      final user =
          await authUseCase.login(email: event.email, password: event.password);

      AppLogger.info('User acquired: $user');
      // Dispatch SessionStarted to GlobalSessionBloc
      globalSessionBloc.add(SessionStarted());

      // Emit success state with user data upon successful login
      emit(AuthSuccess());
      AppLogger.info('AuthSuccess state emitted');
    } catch (e, stackTrace) {
      // Handle errors by emitting failure state and logging the error
      emit(AuthFailure(e.toString()));
      AppLogger.error('AuthFailure state emitted with error', e, stackTrace);
    }
  }

  /// Handles the verifyEmailRequested event
  Future<void> _onConfirmEmailRequested(
      VerifyEmailRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authUseCase.verifyEmail(email: event.email, code: event.code);
      emit(AuthSuccess()); // No user data needed for email verification
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  /// Handles googleSignInRequested event
  Future<void> _onGoogleSignInRequested(
      GoogleSignInRequested event, Emitter<AuthState> emit) async {
    AppLogger.info('GoogleSignInRequested event received');

    // Emit loading state
    emit(AuthLoading());
    AppLogger.debug('AuthLoading state emitted for Google Sign-In');

    try {
      // Perform Google sign-in (update the method with actual logic)
      await authUseCase.signInWithGoogle(event.idToken);
      AppLogger.info('AuthUsecase called googleSignIn');
      // Dispatch SessionStarted to GlobalSessionBloc
      globalSessionBloc.add(SessionStarted());

      // Emit success state with user data
      emit(AuthSuccess());
      AppLogger.info('AuthSuccess state emitted');
    } catch (e, stackTrace) {
      // Emit failure state
      emit(AuthFailure(e.toString()));
      AppLogger.error(
          'AuthFailure state emitted for Google Sign-In', e, stackTrace);
    }
  }
}
