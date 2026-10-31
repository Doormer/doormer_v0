import 'dart:convert';

import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/core/utils/invite_code_storage/invite_code_storage.dart';
import 'package:universal_html/html.dart' as html;

/// Keeps the code in the browser's local storage, so it survives closing the
/// tab, with the time it was kept.
///
/// Where the browser has local storage turned off, using it throws. Each use
/// is caught and logged instead: [keep] and [forget] then do nothing, and
/// [read] finds no code, so a page that reads it still opens.
class InviteCodeStorageWeb implements InviteCodeStorage {
  static const _key = 'friend_invite_code';

  final DateTime Function() _now;
  final Map<String, String> Function() _localStorage;

  InviteCodeStorageWeb({
    DateTime Function() now = DateTime.now,
    Map<String, String> Function() localStorage = _browserLocalStorage,
  })  : _now = now,
        _localStorage = localStorage;

  // Got on each use, inside a try, as where local storage is turned off even
  // getting it can throw.
  static Map<String, String> _browserLocalStorage() => html.window.localStorage;

  @override
  Future<void> keep(String code) async {
    try {
      _localStorage()[_key] = jsonEncode({
        'code': code,
        'kept_at': _now().toUtc().toIso8601String(),
      });
    } catch (e, stackTrace) {
      AppLogger.error('The invite code could not be kept in local storage',
          error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<String?> read() async {
    final String? saved;
    try {
      saved = _localStorage()[_key];
    } catch (e, stackTrace) {
      AppLogger.error('Local storage could not be read',
          error: e, stackTrace: stackTrace);
      return null;
    }
    if (saved == null) return null;
    try {
      final json = jsonDecode(saved) as Map<String, dynamic>;
      final code = json['code'] as String;
      final keptAt = DateTime.parse(json['kept_at'] as String);
      if (!InviteCodeStorage.isFresh(keptAt, _now())) {
        await forget();
        return null;
      }
      return code;
    } catch (e, stackTrace) {
      AppLogger.error('The kept invite code could not be read',
          error: e, stackTrace: stackTrace);
      await forget();
      return null;
    }
  }

  @override
  Future<void> forget() async {
    try {
      _localStorage().remove(_key);
    } catch (e, stackTrace) {
      AppLogger.error('The invite code could not be removed from local storage',
          error: e, stackTrace: stackTrace);
    }
  }
}
