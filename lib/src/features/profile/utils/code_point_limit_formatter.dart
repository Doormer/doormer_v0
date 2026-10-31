import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Caps text at [maxCodePoints] Unicode code points, as the API counts a
/// report's note. Flutter's `maxLength` counts characters as people see them
/// instead, and one of those can be several code points: 👍🏽 is two.
///
/// Otherwise it works as `maxLength` does on the web. Once the text is full,
/// more typing is ignored. Text that goes past the cap is cut at the end, but
/// only between whole characters, so an emoji is never cut in half. While an
/// input method is composing, as when typing Japanese, it waits until the
/// composing ends.
class CodePointLimitFormatter extends TextInputFormatter {
  final int maxCodePoints;

  const CodePointLimitFormatter(this.maxCodePoints);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.runes.length <= maxCodePoints) return newValue;
    if (oldValue.text.runes.length == maxCodePoints &&
        !oldValue.composing.isValid) {
      return oldValue;
    }
    if (newValue.composing.isValid) return newValue;
    return _cut(newValue);
  }

  /// [value] with only the whole characters at its start that fit the cap.
  TextEditingValue _cut(TextEditingValue value) {
    var codePoints = 0;
    var end = 0;
    for (final character in value.text.characters) {
      codePoints += character.runes.length;
      if (codePoints > maxCodePoints) break;
      end += character.length;
    }
    return TextEditingValue(
      text: value.text.substring(0, end),
      selection: value.selection.copyWith(
        baseOffset: math.min(value.selection.start, end),
        extentOffset: math.min(value.selection.end, end),
      ),
    );
  }
}
