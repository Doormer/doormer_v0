import 'package:doormer/src/features/profile/utils/upper_case_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = UpperCaseFormatter();

  test('puts a pasted code in capitals, and the selection stays where it was',
      () {
    const pasted = TextEditingValue(
      text: 'k7qm-2xpa',
      selection: TextSelection(baseOffset: 2, extentOffset: 6),
    );

    expect(
      formatter.formatEditUpdate(TextEditingValue.empty, pasted),
      const TextEditingValue(
        text: 'K7QM-2XPA',
        selection: TextSelection(baseOffset: 2, extentOffset: 6),
      ),
    );
  });

  test('changes only the letters a to z, so the text keeps its length', () {
    // In capitals ß is SS, which would leave the cursor short of the end.
    const typed = TextEditingValue(
      text: 'straße',
      selection: TextSelection.collapsed(offset: 6),
    );

    expect(
      formatter.formatEditUpdate(TextEditingValue.empty, typed),
      const TextEditingValue(
        text: 'STRAßE',
        selection: TextSelection.collapsed(offset: 6),
      ),
    );
  });

  test('waits for an input method to finish composing', () {
    const composing = TextEditingValue(
      text: 'ab',
      selection: TextSelection.collapsed(offset: 2),
      composing: TextRange(start: 0, end: 2),
    );
    const committed = TextEditingValue(
      text: 'ab',
      selection: TextSelection.collapsed(offset: 2),
    );

    expect(formatter.formatEditUpdate(TextEditingValue.empty, composing),
        composing);
    expect(formatter.formatEditUpdate(composing, committed).text, 'AB');
  });
}
