import 'package:doormer/src/core/utils/invite_code_storage/invite_code_storage.dart';

/// Keeps the code in memory, for tests.
class InMemoryInviteCodeStorage implements InviteCodeStorage {
  final DateTime Function() _now;
  String? _code;
  DateTime? _keptAt;

  InMemoryInviteCodeStorage({DateTime Function() now = DateTime.now})
      : _now = now;

  @override
  Future<void> keep(String code) async {
    _code = code;
    _keptAt = _now();
  }

  @override
  Future<String?> read() async {
    final keptAt = _keptAt;
    if (keptAt == null || !InviteCodeStorage.isFresh(keptAt, _now())) {
      return null;
    }
    return _code;
  }

  @override
  Future<void> forget() async {
    _code = null;
    _keptAt = null;
  }
}
