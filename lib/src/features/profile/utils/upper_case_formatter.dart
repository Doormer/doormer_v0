import 'package:flutter/services.dart';

/// Shows the letters a to z as capitals, however they are typed or pasted,
/// as friend codes are written. A phone's keyboard already types capitals
/// when the box asks for them, but a computer's keyboard doesn't.
///
/// Each of those letters becomes one capital, so the text keeps its length
/// and the selection stays where it was. While an input method is composing,
/// as when typing Chinese, it waits until the composing ends.
class UpperCaseFormatter extends TextInputFormatter {
  const UpperCaseFormatter();

  static final _lowerCaseLetter = RegExp('[a-z]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed ||
        !newValue.text.contains(_lowerCaseLetter)) {
      return newValue;
    }
    return newValue.copyWith(
      text: newValue.text.replaceAllMapped(
        _lowerCaseLetter,
        (letter) => letter[0]!.toUpperCase(),
      ),
    );
  }
}
