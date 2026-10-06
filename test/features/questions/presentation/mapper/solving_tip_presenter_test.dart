import 'package:doormer/src/features/questions/presentation/mapper/solving_tip_presenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('there are eight different tips', () {
    expect(solvingTips, hasLength(8));
    expect(solvingTips.toSet(), hasLength(8));
  });

  test('tips stay pinned in their reviewed order', () {
    expect(solvingTips, [
      'Read the question twice and underline what it asks you to find.',
      'Write down what the question gives you before you start working.',
      'Estimate the answer first, so you can tell if your result is way off.',
      'Draw a quick sketch for any question about shapes, angles or distances.',
      'Keep the units on every line. They catch mistakes early.',
      'Check your answer by putting it back into the original question.',
      'Stuck? Try the same question with simpler numbers to see the pattern.',
      'Look over your working one line at a time to find a slip.',
    ]);
  });

  test('the same photo always gets the same tip', () {
    expect(
      solvingTipFor(photoSize: 48213),
      solvingTipFor(photoSize: 48213),
    );
  });

  test('every tip can come up', () {
    final shown = {
      for (var size = 0; size < solvingTips.length; size++)
        solvingTipFor(photoSize: size),
    };

    expect(shown, solvingTips.toSet());
  });

  test('a photo with no bytes gets the first tip', () {
    expect(
      solvingTipFor(photoSize: 0),
      'Read the question twice and underline what it asks you to find.',
    );
  });
}
