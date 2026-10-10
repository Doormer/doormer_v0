import 'package:doormer/src/core/routes/route_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('signed out', () {
    for (final path in [
      '/questions/photo',
      '/questions/abc/solution',
      '/saved',
      '/collection',
      '/profile',
    ]) {
      test('$path goes to /auth/login', () {
        expect(redirectFor(path, isSignedIn: false), '/auth/login');
      });
    }

    test('/ goes to /auth', () {
      expect(redirectFor('/', isSignedIn: false), '/auth');
    });

    for (final path in ['/auth', '/auth/signup', '/auth/login']) {
      test('$path stays', () {
        expect(redirectFor(path, isSignedIn: false), isNull);
      });
    }
  });

  group('signed in', () {
    for (final path in ['/', '/auth', '/auth/signup', '/auth/login']) {
      test('$path goes to /questions/photo', () {
        expect(redirectFor(path, isSignedIn: true), '/questions/photo');
      });
    }

    for (final path in [
      '/questions/photo',
      '/saved',
      '/collection',
      '/profile'
    ]) {
      test('$path stays', () {
        expect(redirectFor(path, isSignedIn: true), isNull);
      });
    }
  });

  group('either way', () {
    for (final path in [
      '/auth/registration',
      '/auth/registration-complete',
      '/no-such-page',
    ]) {
      for (final signedIn in [true, false]) {
        test('$path stays (signed in: $signedIn)', () {
          expect(redirectFor(path, isSignedIn: signedIn), isNull);
        });
      }
    }
  });

  group('hasSignedInSession', () {
    test('an access token alone is signed in', () {
      expect(hasSignedInSession(accessToken: 'access'), isTrue);
    });

    test('a refresh token alone is signed in, as after a browser restart', () {
      expect(hasSignedInSession(refreshToken: 'refresh'), isTrue);
    });

    test('no tokens, or only empty ones, is signed out', () {
      expect(hasSignedInSession(), isFalse);
      expect(hasSignedInSession(accessToken: '', refreshToken: ''), isFalse);
    });
  });
}
