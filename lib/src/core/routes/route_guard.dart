import 'package:doormer/src/core/utils/invite_code_storage/invite_code_storage.dart';
import 'package:doormer/src/core/utils/token_storage/token_storage.dart';

/// The pages on the nav bar. A signed-in student with a kept invite code who
/// heads for one is sent to the invite's check instead.
const _navBarPages = {'/saved', '/questions/photo', '/collection', '/profile'};

final _invitePath = RegExp(r'^/add/([^/]+)$');

/// Where a navigation to [path] should go instead, or null to let it through.
///
/// [savedInviteCode] is the code of an invite link the student opened while
/// signed out, kept until its check has been shown.
///
/// Kept free of GoRouter so every rule can be unit tested.
String? redirectFor(
  String path, {
  required bool isSignedIn,
  String? savedInviteCode,
}) {
  const authEntry = {'/auth', '/auth/signup', '/auth/login'};
  final needsSession = path.startsWith('/questions/') ||
      path == '/saved' ||
      path.startsWith('/saved/') ||
      path == '/collection' ||
      path == '/profile' ||
      path.startsWith('/profile/');

  if (isSignedIn) {
    final openedInvite = inviteCodeIn(path);
    if (openedInvite != null) return _checkOf(openedInvite);
    if (path == '/' || authEntry.contains(path)) return '/questions/photo';
    if (savedInviteCode != null && _navBarPages.contains(path)) {
      return _checkOf(savedInviteCode);
    }
    return null;
  }
  if (path == '/') return '/auth';
  if (needsSession) return '/auth/login';
  return null;
}

/// The friend code in an invite link's path, `/add/<code>`, or null for any
/// other path.
String? inviteCodeIn(String path) => _invitePath.firstMatch(path)?.group(1);

/// The check of an invite's code, inside the Profile tab.
String _checkOf(String code) => '/profile/add/$code';

/// What the router does with a navigation to [path]: while the student is
/// signed out, it keeps the code of an invite link being opened, for 7 days.
/// Then it applies [redirectFor] to the stored session and kept code.
///
/// Sign-in ends on the older registration pages, so the code waits for the
/// first app page the student reaches. A signed-in student goes straight to
/// the check, which takes the code from its path, so nothing is kept. Back to
/// the link would otherwise keep the code again, and the check already
/// showing wouldn't forget it.
Future<String?> guardNavigation(
  String path, {
  required TokenStorage tokens,
  required InviteCodeStorage inviteCodes,
}) async {
  final isSignedIn = hasSignedInSession(
    accessToken: await tokens.getAccessToken(),
    refreshToken: await tokens.getRefreshToken(),
  );
  final openedInvite = inviteCodeIn(path);
  if (openedInvite != null && !isSignedIn) {
    await inviteCodes.keep(openedInvite);
  }
  return redirectFor(
    path,
    isSignedIn: isSignedIn,
    savedInviteCode: await inviteCodes.read(),
  );
}

/// Whether the stored tokens mean the student is signed in.
///
/// A refresh token alone counts: the access token's cookie is gone after a
/// browser restart, and the first API call renews it.
bool hasSignedInSession({String? accessToken, String? refreshToken}) =>
    (accessToken?.isNotEmpty ?? false) || (refreshToken?.isNotEmpty ?? false);
