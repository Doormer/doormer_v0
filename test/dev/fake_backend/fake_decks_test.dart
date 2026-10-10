import 'package:doormer/src/dev/fake_backend/fake_decks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fake Cinder deck uses replacement PNG art', () {
    final deck = fakeDeckById('cinder-01');
    expect(deck, isNotNull);
    expect(deck!.cards, hasLength(6));

    const artRoot =
        'https://takadev1cv.blob.core.windows.net/card-art/cinder-01';
    const expected = {
      'flint': '$artRoot/flint.png',
      'wick': '$artRoot/wick.png',
      'rasp': '$artRoot/rasp.png',
      'scorch': '$artRoot/scorch.png',
      'kiln': '$artRoot/kiln.png',
      'crucible': '$artRoot/crucible.png',
    };
    expect(
      {for (final card in deck.cards) card.id: card.artUrl},
      expected,
    );
  });
}
