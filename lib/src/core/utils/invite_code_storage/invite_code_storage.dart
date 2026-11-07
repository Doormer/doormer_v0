/// Keeps the friend code of an invite link the student opened while signed
/// out, so the check can open once they have signed in and reached the app,
/// which may be in a later visit.
abstract class InviteCodeStorage {
  /// How long a kept code lasts.
  static const lifetime = Duration(days: 7);

  /// Whether a code kept at [keptAt] is still good at [now].
  static bool isFresh(DateTime keptAt, DateTime now) =>
      now.difference(keptAt) < lifetime;

  /// Keeps [code], in place of any code kept before.
  Future<void> keep(String code);

  /// The kept code, or null when there is none or it is older than
  /// [lifetime].
  Future<String?> read();

  Future<void> forget();
}
