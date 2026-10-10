import 'package:doormer/src/dev/fake_backend/fake_backend_state.dart';
import 'package:doormer/src/dev/fake_backend/fake_request.dart';
import 'package:doormer/src/dev/fake_backend/fake_response.dart';
import 'package:doormer/src/dev/fake_backend/fake_route.dart';

/// Signing up, signing in and renewing the session. Any email and password
/// sign in, as the one fake student.
class AuthRoutes {
  final FakeBackendState _state;

  AuthRoutes(this._state);

  List<FakeRoute> get routes => [
        FakeRoute('POST', '/v1/signup', _signUp, needsToken: false),
        FakeRoute('POST', '/v1/login', _signIn, needsToken: false),
        // The app calls this, but `taka-api` has no such route.
        FakeRoute('POST', '/confirm-email', _confirmEmail, needsToken: false),
        // The app sends the refresh token as the bearer token.
        FakeRoute('POST', '/v1/token/refresh', _renewAccessToken),
      ];

  /// A new student has not registered yet, so the app opens registration.
  FakeResponse _signUp(FakeRequest request) {
    _state.registrationStatus = 0;
    return _signedIn();
  }

  FakeResponse _signIn(FakeRequest request) => _signedIn();

  FakeResponse _confirmEmail(FakeRequest request) => const FakeResponse.ok({});

  FakeResponse _renewAccessToken(FakeRequest request) =>
      FakeResponse.ok({'access_token': _state.newToken('access')});

  FakeResponse _signedIn() => FakeResponse.ok({
        'access_token': _state.newToken('access'),
        'refresh_token': _state.newToken('refresh'),
        'user_info': {'user_registration_status': _state.registrationStatus},
      });
}
