import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/profile/domain/usecase/sign_out_usecase.dart';
import 'package:doormer/src/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSessionService implements SessionService {
  Object? logoutError;
  int logouts = 0;

  @override
  Future<void> logout() async {
    logouts++;
    final error = logoutError;
    if (error != null) throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(AppLogger.disable);

  late _FakeSessionService session;
  setUp(() => session = _FakeSessionService());

  ProfileBloc build() => ProfileBloc(signOut: SignOutUseCase(session));

  blocTest<ProfileBloc, ProfileState>(
    'signs out',
    build: build,
    act: (bloc) => bloc.add(const SignOutRequested()),
    expect: () => [const ProfileSigningOut(), const ProfileSignedOut()],
    verify: (_) => expect(session.logouts, 1),
  );

  blocTest<ProfileBloc, ProfileState>(
    'reports a typed failure',
    build: build,
    setUp: () => session.logoutError = DatabaseFailure('Could not sign out.'),
    act: (bloc) => bloc.add(const SignOutRequested()),
    expect: () => [
      const ProfileSigningOut(),
      const ProfileError('Could not sign out.'),
    ],
  );

  blocTest<ProfileBloc, ProfileState>(
    'reports an unexpected error',
    build: build,
    setUp: () => session.logoutError = StateError('boom'),
    act: (bloc) => bloc.add(const SignOutRequested()),
    expect: () => [
      const ProfileSigningOut(),
      const ProfileError('Could not sign out. Please try again.'),
    ],
  );
}
