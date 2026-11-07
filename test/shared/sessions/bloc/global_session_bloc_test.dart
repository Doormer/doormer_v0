import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:doormer/src/shared/sessions/bloc/global_session_bloc.dart';
import 'package:doormer/src/shared/user/entity/user.dart';
import 'package:flutter_test/flutter_test.dart';

/// Starting a session never calls the session service.
class _UnusedSessionService implements SessionService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  // main.dart resets what belonged to whoever was signed in before each time
  // the session becomes active. Sign-out doesn't end the session, so every
  // sign-in has to be heard as a new one.
  blocTest<GlobalSessionBloc, GlobalSessionState>(
    'announces every sign-in, even when the same student signs in again',
    build: () => GlobalSessionBloc(sessionService: _UnusedSessionService()),
    act: (bloc) {
      const student = User();
      bloc
        ..add(const SessionStarted(student))
        ..add(const SessionStarted(student));
    },
    expect: () => [
      isA<SessionLoadingState>(),
      isA<SessionActiveState>(),
      isA<SessionLoadingState>(),
      isA<SessionActiveState>(),
    ],
  );
}
