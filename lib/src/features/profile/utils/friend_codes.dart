/// Friend codes as students see and type them, and the invite links that
/// carry them.
abstract final class FriendCodes {
  /// The characters a code is made of. There's no 0, 1, I or O, the ones
  /// most easily mistaken for others.
  static const alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  static const length = 8;

  static final _spacesAndDashes = RegExp(r'[\s\-\u2010-\u2015]');

  /// [code], 8 characters with no dash, as students see it: `K7QM-2XPA`.
  static String display(String code) => code.length == length
      ? '${code.substring(0, 4)}-${code.substring(4)}'
      : code;

  /// A typed code as the API takes it: in capitals, with no spaces or dashes.
  static String normalise(String typed) =>
      typed.toUpperCase().replaceAll(_spacesAndDashes, '');

  /// Whether [code] could be anyone's: 8 characters from [alphabet]. A code
  /// that can't is never looked up, as every look-up counts toward the 50 a
  /// day.
  static bool isWellFormed(String code) =>
      code.length == length &&
      code.split('').every((character) => alphabet.contains(character));

  /// The invite link for [code]: the app's own address, then `/add/` and the
  /// code with no dash.
  static String inviteLink(String code, {required Uri appAddress}) =>
      '${appAddress.origin}/add/$code';
}
