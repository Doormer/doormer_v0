import 'package:bloc/bloc.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/auth/domain/usecase/auth_usecase.dart';
import 'package:doormer/src/shared/sessions/bloc/global_session_bloc.dart';
import 'package:doormer/src/shared/user/entity/user.dart';
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
      final user = await authUseCase.signup(
        email: event.email,
        password: event.password,
      );

      // Dispatch SessionStarted to GlobalSessionBloc
      globalSessionBloc.add(SessionStarted(user));

      // Emit success state with user data upon successful signup
      emit(AuthSuccess());
      AppLogger.info('AuthSuccess state emitted.');
    } on Failure catch (f, stackTrace) {
      emit(AuthError(f.message));
      AppLogger.error('Signup failed', error: f, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      emit(AuthError('An unexpected error occurred'));
      AppLogger.error('Signup unexpected error',
          error: e, stackTrace: stackTrace);
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
      globalSessionBloc.add(SessionStarted(user));

      // Emit success state with user data upon successful login
      emit(AuthSuccess());

      AppLogger.info('AuthSuccess state emitted');
    } on Failure catch (f, stackTrace) {
      emit(AuthError(f.message));
      AppLogger.error('Login failed', error: f, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      emit(AuthError('An unexpected error occurred'));
      AppLogger.error('Login unexpected error',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Handles the verifyEmailRequested event
  Future<void> _onConfirmEmailRequested(
      VerifyEmailRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authUseCase.verifyEmail(email: event.email, code: event.code);
      emit(AuthSuccess()); // No user data needed for email verification
    } on Failure catch (f, stackTrace) {
      emit(AuthError(f.message));
      AppLogger.error('Email verification failed',
          error: f, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      emit(AuthError('An unexpected error occurred'));
      AppLogger.error('Email verification unexpected error',
          error: e, stackTrace: stackTrace);
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
      final user = await authUseCase.signInWithGoogle(event.idToken);
      AppLogger.info('AuthUsecase called googleSignIn');
      // Dispatch SessionStarted to GlobalSessionBloc
      globalSessionBloc.add(SessionStarted(user));

      // Emit success state with user data
      emit(AuthSuccess());
      AppLogger.info('AuthSuccess state emitted');
    } on Failure catch (f, stackTrace) {
      emit(AuthError(f.message));
      AppLogger.error('Google sign-in failed',
          error: f, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      emit(AuthError('An unexpected error occurred'));
      AppLogger.error('Google sign-in unexpected error',
          error: e, stackTrace: stackTrace);
    }
  }
}
