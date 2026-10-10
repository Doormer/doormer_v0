/// Where a navigation to [path] should go instead, or null to let it through.
///
/// Kept free of GoRouter so every rule can be unit tested.
String? redirectFor(String path, {required bool isSignedIn}) {
  const authEntry = {'/auth', '/auth/signup', '/auth/login'};
  final needsSession = path.startsWith('/questions/') ||
      path == '/saved' ||
      path == '/collection' ||
      path == '/profile';

  if (isSignedIn) {
    if (path == '/' || authEntry.contains(path)) return '/questions/photo';
    return null;
  }
  if (path == '/') return '/auth';
  if (needsSession) return '/auth/login';
  return null;
}

/// Whether the stored tokens mean the student is signed in.
///
/// A refresh token alone counts: the access token's cookie is gone after a
/// browser restart, and the first API call renews it.
bool hasSignedInSession({String? accessToken, String? refreshToken}) =>
    (accessToken?.isNotEmpty ?? false) || (refreshToken?.isNotEmpty ?? false);
