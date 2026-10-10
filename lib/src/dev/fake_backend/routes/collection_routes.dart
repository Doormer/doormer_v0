import 'dart:math';

import 'package:doormer/src/dev/fake_backend/fake_backend_state.dart';
import 'package:doormer/src/dev/fake_backend/fake_decks.dart';
import 'package:doormer/src/dev/fake_backend/fake_request.dart';
import 'package:doormer/src/dev/fake_backend/fake_response.dart';
import 'package:doormer/src/dev/fake_backend/fake_route.dart';

/// The decks, their cards, draws and shatters, by `taka-api`'s rules, except
/// that a rare card is never guaranteed and specials come up more often.
class CollectionRoutes {
  final FakeBackendState _state;
  final Random _random;

  CollectionRoutes(this._state, this._random);

  List<FakeRoute> get routes => [
        FakeRoute('POST', '/v1/collection/decks', _decks),
        FakeRoute('POST', '/v1/collection/cards', _cards),
        FakeRoute('POST', '/v1/collection/draw', _draw),
        FakeRoute('POST', '/v1/collection/shatter', _shatter),
      ];

  FakeResponse _decks(FakeRequest request) => FakeResponse.ok({
        'quark_balance': _state.quarkBalance,
        'decks': [
          for (final deck in fakeDecks)
            {
              'deck_id': deck.id,
              'name': deck.name,
              'draw_cost': fakeDrawCost,
              'cards_total': deck.cards.length,
              'cards_held': deck.cards
                  .where((card) => _holdingOf(deck, card).totalCopies > 0)
                  .length,
            },
        ],
      });

  FakeResponse _cards(FakeRequest request) {
    final deck = _deckIn(request);
    if (deck == null) return const FakeResponse(404, 'deck not found');
    return FakeResponse.ok({
      'quark_balance': _state.quarkBalance,
      'deck': {
        'deck_id': deck.id,
        'name': deck.name,
        'draw_cost': fakeDrawCost,
      },
      'cards': [
        for (final card in deck.cards) _cardJson(card, _holdingOf(deck, card)),
      ],
    });
  }

  FakeResponse _draw(FakeRequest request) {
    final deck = _deckIn(request);
    if (deck == null) return const FakeResponse(404, 'deck not found');
    if (_state.quarkBalance < fakeDrawCost) {
      return const FakeResponse(409, 'not enough quarks');
    }

    _state.quarkBalance -= fakeDrawCost;
    final special = _random.nextDouble() < fakeSpecialDrawRate;
    final card = _pickCard(deck, _rollRarity(), special: special);
    final holding = _holdingOf(deck, card);
    final result = holding.totalCopies == 0
        ? 'new_card'
        : special && holding.specialCopies == 0
            ? 'upgrade'
            : 'duplicate';
    if (special) {
      holding.specialCopies++;
    } else {
      holding.standardCopies++;
    }

    return FakeResponse.ok({
      'quark_balance': _state.quarkBalance,
      // As in the real API, the drawn card's own counts are zero:
      // copies_after carries the count.
      'card': _cardJson(card, FakeHolding()),
      'variant': special ? 'special' : 'standard',
      'result': result,
      'copies_after': holding.totalCopies,
    });
  }

  FakeResponse _shatter(FakeRequest request) {
    final deck = _deckIn(request);
    final card = deck?.cardById(request.fields['card_id']?.toString());
    if (deck == null || card == null) {
      return const FakeResponse(404, 'card not found');
    }
    final variant = request.fields['variant'];
    if (variant != 'standard' && variant != 'special') {
      return const FakeResponse(400, 'unknown variant');
    }

    final special = variant == 'special';
    final holding = _holdingOf(deck, card);
    final copiesOfVariant =
        special ? holding.specialCopies : holding.standardCopies;
    // The last copy of a card is never shattered.
    if (copiesOfVariant == 0 || holding.totalCopies < 2) {
      return const FakeResponse(409, 'no spare copy');
    }

    if (special) {
      holding.specialCopies--;
    } else {
      holding.standardCopies--;
    }
    final quarksGained = card.rarity.shatterQuarks(special: special);
    _state.quarkBalance += quarksGained;
    return FakeResponse.ok({
      'quark_balance': _state.quarkBalance,
      'quarks_gained': quarksGained,
      'card_id': card.id,
      'standard_copies': holding.standardCopies,
      'special_copies': holding.specialCopies,
    });
  }

  FakeRarity _rollRarity() {
    var roll = _random.nextDouble();
    for (final rarity in FakeRarity.values) {
      if (roll < rarity.drawRate) return rarity;
      roll -= rarity.drawRate;
    }
    return FakeRarity.values.last;
  }

  /// A standard draw picks a card not held yet, if the rarity has one. A
  /// special draw picks from the whole rarity.
  FakeCard _pickCard(FakeDeck deck, FakeRarity rarity,
      {required bool special}) {
    final ofRarity = deck.cards.where((card) => card.rarity == rarity).toList();
    final notHeld = ofRarity
        .where((card) => _holdingOf(deck, card).totalCopies == 0)
        .toList();
    final choices = !special && notHeld.isNotEmpty ? notHeld : ofRarity;
    return choices[_random.nextInt(choices.length)];
  }

  FakeDeck? _deckIn(FakeRequest request) =>
      fakeDeckById(request.fields['deck_id']?.toString());

  FakeHolding _holdingOf(FakeDeck deck, FakeCard card) =>
      _state.holdingOf(deck.id, card.id);

  Map<String, Object?> _cardJson(FakeCard card, FakeHolding holding) => {
        'card_id': card.id,
        'name': card.name,
        'rarity': card.rarity.name,
        'art_url': card.artUrl,
        'attributes': {
          'scale_label': card.scaleLabel,
          'description': card.description,
        },
        'standard_copies': holding.standardCopies,
        'special_copies': holding.specialCopies,
        'standard_shatter_quarks': card.rarity.shatterQuarks(special: false),
        'special_shatter_quarks': card.rarity.shatterQuarks(special: true),
      };
}
