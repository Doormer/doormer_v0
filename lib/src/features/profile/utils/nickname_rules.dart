/// The API's rules for a nickname, with the API's own words, except its
/// blocked word list. The app checks a nickname before sending it, so the only
/// refusal it normally meets is the word list.
abstract final class NicknameRules {
  static const minLength = 3;
  static const maxLength = 16;
  static const maxNumbers = 4;

  static const lengthProblem = 'Use 3 to 16 characters.';
  static const characterProblem =
      'Use letters, numbers, spaces, dots, dashes or underscores.';
  static const letterProblem = 'Include at least one letter.';
  static const numbersProblem = 'Use no more than 4 numbers.';

  static final _spaces = RegExp(r'\s+');
  // a–z and A–Z, and the letters in U+00C0–U+024F (Latin-1 Supplement from À,
  // Latin Extended-A and Latin Extended-B) and U+1E00–U+1EFF (Latin Extended
  // Additional): the letters students type, accents and macrons included.
  // Other forms, such as fullwidth or small capital letters, are refused, as
  // the API refuses them. The API's blocked word list, not this check, deals
  // with letters written to hide a word.
  static final _latinLetter =
      RegExp(r'^[A-Za-z\u00C0-\u024F\u1E00-\u1EFF]$', unicode: true);
  static final _letter = RegExp(r'^\p{L}$', unicode: true);
  static final _number = RegExp(r'^[0-9]$');

  /// [raw] as it is saved: the spaces at either end removed, and each run of
  /// spaces made one.
  static String tidy(String raw) => raw.trim().replaceAll(_spaces, ' ');

  /// Why [raw] can't be a nickname, in the API's words, or null when it can.
  ///
  /// Checked in the API's order: length, characters, a letter, numbers.
  /// Length counts characters as the API does, one per code point.
  static String? problemWith(String raw) {
    final characters = [
      for (final rune in tidy(raw).runes) String.fromCharCode(rune),
    ];
    if (characters.length < minLength || characters.length > maxLength) {
      return lengthProblem;
    }

    var letters = 0;
    var numbers = 0;
    for (final character in characters) {
      if (_latinLetter.hasMatch(character) && _letter.hasMatch(character)) {
        letters++;
      } else if (_number.hasMatch(character)) {
        numbers++;
      } else if (!' ._-'.contains(character)) {
        return characterProblem;
      }
    }
    if (letters == 0) return letterProblem;
    if (numbers > maxNumbers) return numbersProblem;
    return null;
  }
}
