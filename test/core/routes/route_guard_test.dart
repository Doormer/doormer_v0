import 'package:doormer/src/core/routes/route_guard.dart';
import 'package:doormer/src/core/utils/invite_code_storage/in_memory_invite_code_storage.dart';
import 'package:doormer/src/core/utils/token_storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTokenStorage implements TokenStorage {
  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('signed out', () {
    for (final path in [
      '/questions/photo',
      '/questions/abc/solution',
      '/questions/photo/abc/solution',
      '/saved',
      '/saved/abc/solution',
      '/collection',
      '/profile',
      '/profile/add',
      '/profile/friends/42/cards',
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
      '/questions/photo/abc/solution',
      '/saved',
      '/saved/abc/solution',
      '/collection',
      '/profile',
      '/profile/add',
      '/profile/friends/42/cards',
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

  group('an invite link', () {
    test('signed out, stays, for the invite page', () {
      expect(redirectFor('/add/K7QM2XPA', isSignedIn: false), isNull);
    });

    test('signed in, goes to its check', () {
      expect(redirectFor('/add/K7QM2XPA', isSignedIn: true),
          '/profile/add/K7QM2XPA');
    });

    for (final path in [
      '/saved',
      '/questions/photo',
      '/collection',
      '/profile',
    ]) {
      test('signed in with a code kept, $path goes to its check', () {
        expect(
          redirectFor(path, isSignedIn: true, savedInviteCode: 'K7QM2XPA'),
          '/profile/add/K7QM2XPA',
        );
      });
    }

    for (final path in [
      '/profile/add/K7QM2XPA',
      '/profile/setup',
      '/saved/abc/solution',
      '/auth/registration-complete',
    ]) {
      test('signed in with a code kept, $path stays', () {
        expect(
          redirectFor(path, isSignedIn: true, savedInviteCode: 'K7QM2XPA'),
          isNull,
        );
      });
    }

    test('signed out, a code kept changes nothing', () {
      expect(
        redirectFor('/saved', isSignedIn: false, savedInviteCode: 'K7QM2XPA'),
        '/auth/login',
      );
    });
  });

  group('inviteCodeIn', () {
    test("reads an invite link's code", () {
      expect(inviteCodeIn('/add/K7QM2XPA'), 'K7QM2XPA');
    });

    test('finds none in any other path', () {
      for (final path in [
        '/add',
        '/add/',
        '/add/K7QM2XPA/more',
        '/profile/add/K7QM2XPA',
      ]) {
        expect(inviteCodeIn(path), isNull, reason: path);
      }
    });
  });

  group('guardNavigation', () {
    late DateTime now;
    late _FakeTokenStorage tokens;
    late InMemoryInviteCodeStorage inviteCodes;

    setUp(() {
      now = DateTime.utc(2026, 10, 26, 9);
      tokens = _FakeTokenStorage();
      inviteCodes = InMemoryInviteCodeStorage(now: () => now);
    });

    Future<String?> guard(String path) =>
        guardNavigation(path, tokens: tokens, inviteCodes: inviteCodes);

    test('keeps the code of an invite link opened while signed out', () async {
      expect(await guard('/add/K7QM2XPA'), isNull);
      expect(await inviteCodes.read(), 'K7QM2XPA');
    });

    test('after signing in, the first app page opens the check', () async {
      await guard('/add/K7QM2XPA');

      tokens.refreshToken = 'refresh';

      expect(await guard('/auth/registration-complete'), isNull);
      expect(await guard('/questions/photo'), '/profile/add/K7QM2XPA');
    });

    test('signed in, opens the check of an invite link and keeps no code',
        () async {
      tokens.accessToken = 'access';

      expect(await guard('/add/K7QM2XPA'), '/profile/add/K7QM2XPA');
      expect(await inviteCodes.read(), isNull,
          reason: 'the check takes the code from its path');
    });

    test('a code kept more than 7 days ago no longer opens the check',
        () async {
      await guard('/add/K7QM2XPA');
      tokens.accessToken = 'access';
      now = now.add(const Duration(days: 7));

      expect(await guard('/questions/photo'), isNull);
    });
  });
}
