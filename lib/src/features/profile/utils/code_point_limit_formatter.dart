import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Caps text at [maxCodePoints] Unicode code points, as the API counts a
/// report's note. Flutter's `maxLength` counts characters as people see them
/// instead, and one of those can be several code points: 👍🏽 is two.
///
/// Otherwise it works as `maxLength` does on the web. Once the text is full,
/// more typing is ignored. Text that goes past the cap is cut at the end, but
/// only between whole characters, so an emoji is never cut in half.
///
/// While an input method is composing, as when typing Japanese, or a word on
/// a keyboard such as Gboard, the text may go past the cap. It is cut when the
/// input method ends the composing. But when the field loses focus,
/// `EditableText` ends the composing with `clearComposing()`, which runs no
/// formatter, so the text can stay past the cap. Whatever sends the text cuts
/// it again with [truncate].
class CodePointLimitFormatter extends TextInputFormatter {
  final int maxCodePoints;

  const CodePointLimitFormatter(this.maxCodePoints);

  /// The whole characters at the start of [text] that fit in [maxCodePoints]
  /// code points.
  static String truncate(String text, int maxCodePoints) {
    var codePoints = 0;
    var end = 0;
    for (final character in text.characters) {
      codePoints += character.runes.length;
      if (codePoints > maxCodePoints) break;
      end += character.length;
    }
    return text.substring(0, end);
  }

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
    final end = truncate(value.text, maxCodePoints).length;
    return TextEditingValue(
      text: value.text.substring(0, end),
      selection: value.selection.copyWith(
        baseOffset: math.min(value.selection.start, end),
        extentOffset: math.min(value.selection.end, end),
      ),
    );
  }
}
