import 'dart:convert';

import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/core/utils/invite_code_storage/invite_code_storage.dart';
import 'package:universal_html/html.dart' as html;

/// Keeps the code in the browser's local storage, so it survives closing the
/// tab, with the time it was kept.
class InviteCodeStorageWeb implements InviteCodeStorage {
  static const _key = 'friend_invite_code';

  final DateTime Function() _now;

  InviteCodeStorageWeb({DateTime Function() now = DateTime.now}) : _now = now;

  @override
  Future<void> keep(String code) async {
    html.window.localStorage[_key] = jsonEncode({
      'code': code,
      'kept_at': _now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<String?> read() async {
    final saved = html.window.localStorage[_key];
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
    html.window.localStorage.remove(_key);
  }
}
