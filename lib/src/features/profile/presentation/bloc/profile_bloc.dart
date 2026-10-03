import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecase/sign_out_usecase.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final SignOutUseCase _signOut;

  ProfileBloc({required SignOutUseCase signOut})
      : _signOut = signOut,
        super(const ProfileInitial()) {
    on<SignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileSigningOut());
    try {
      await _signOut();
      emit(const ProfileSignedOut());
    } on Failure catch (f, stackTrace) {
      emit(ProfileError(f.message));
      AppLogger.error('Sign out failed', error: f, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      emit(const ProfileError('Could not sign out. Please try again.'));
      AppLogger.error(
        'Sign out unexpected error',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
