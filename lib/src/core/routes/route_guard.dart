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
