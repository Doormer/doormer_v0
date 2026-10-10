import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/core/utils/token_storage/token_storage.dart';
import 'package:universal_html/html.dart' as html;

class TokenStorageWeb implements TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  /// Matches RefreshAuth.ExpiresInSec in taka-api: a refresh token is good for
  /// 30 days after login, so its cookie outlives the browser session.
  static const _refreshTokenLifetime = Duration(days: 30);

  String _createCookie(String name, String value, {Duration? maxAge}) {
    final lifetime = maxAge == null ? '' : '; Max-Age=${maxAge.inSeconds}';
    return '$name=${Uri.encodeFull(value)}; path=/$lifetime; Secure; SameSite=Strict';
  }

  String _createDeleteCookie(String name) {
    return '$name=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT; Secure; SameSite=Strict';
  }

  String? _getCookieValue(String name) {
    final cookies = html.document.cookie?.split('; ') ?? [];
    final cookiePrefix = '$name=';
    final cookie = cookies.firstWhere(
      (cookie) => cookie.startsWith(cookiePrefix),
      orElse: () => '',
    );
    return cookie.isEmpty
        ? null
        : Uri.decodeFull(cookie.substring(cookiePrefix.length));
  }

  @override
  Future<void> saveAccessToken(String token) async {
    html.document.cookie = _createCookie(_accessTokenKey, token);
    AppLogger.info('Saved access token');
  }

  @override
  Future<String?> getAccessToken() async {
    return _getCookieValue(_accessTokenKey);
  }

  @override
  Future<void> deleteAccessToken() async {
    html.document.cookie = _createDeleteCookie(_accessTokenKey);
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    html.document.cookie =
        _createCookie(_refreshTokenKey, token, maxAge: _refreshTokenLifetime);
  }

  @override
  Future<String?> getRefreshToken() async {
    return _getCookieValue(_refreshTokenKey);
  }

  @override
  Future<void> deleteRefreshToken() async {
    html.document.cookie = _createDeleteCookie(_refreshTokenKey);
  }

  @override
  Future<void> clearTokens() async {
    await deleteAccessToken();
    await deleteRefreshToken();
  }
}
