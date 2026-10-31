import 'package:doormer/src/features/profile/utils/code_point_limit_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// [text] as typed, with the cursor at its end.
TextEditingValue _typed(String text) => TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

void main() {
  const formatter = CodePointLimitFormatter(4);

  test('cuts text that goes past the cap between whole characters', () {
    // 👍🏽 is two code points: a thumbs up, then a skin tone.
    final capped = formatter.formatEditUpdate(_typed(''), _typed('a👍🏽👍🏽'));

    expect(capped, _typed('a👍🏽'));
  });

  test('once the text is full, ignores more typing', () {
    const full = TextEditingValue(
      text: 'abcd',
      selection: TextSelection.collapsed(offset: 1),
    );
    const typedInside = TextEditingValue(
      text: 'aXbcd',
      selection: TextSelection.collapsed(offset: 2),
    );

    expect(formatter.formatEditUpdate(full, typedInside), full);
  });

  test('waits for an input method to finish composing, then cuts', () {
    final composing = _typed('abcdef').copyWith(
      composing: const TextRange(start: 2, end: 6),
    );

    expect(formatter.formatEditUpdate(_typed('ab'), composing), composing);
    expect(
      formatter.formatEditUpdate(composing, _typed('abcdef')),
      _typed('abcd'),
    );
  });
}
