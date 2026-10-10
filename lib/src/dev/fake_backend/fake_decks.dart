// The real decks and rules, copied from `taka-api/etc/decks/`.

/// What a draw costs, in both decks.
const fakeDrawCost = 40;

/// One draw in five is special. The real rate is one in twenty; it is raised
/// so upgrades show up when testing.
const fakeSpecialDrawRate = 0.2;

/// A special copy shatters for this many times a standard one.
const fakeSpecialShatterMultiplier = 2;

enum FakeRarity {
  common(drawRate: 0.6, shatterFraction: 0.13),
  uncommon(drawRate: 0.3, shatterFraction: 0.27),
  rare(drawRate: 0.1, shatterFraction: 0.47);

  /// How often a draw lands on this rarity.
  final double drawRate;

  /// The share of the draw cost that shattering a standard copy gives back.
  final double shatterFraction;

  const FakeRarity({required this.drawRate, required this.shatterFraction});

  /// What shattering one copy earns.
  int shatterQuarks({required bool special}) {
    final quarks = (fakeDrawCost * shatterFraction).round();
    return special ? quarks * fakeSpecialShatterMultiplier : quarks;
  }
}

class FakeCard {
  final String id;
  final String name;
  final FakeRarity rarity;
  final String scaleLabel;
  final String description;
  final String artUrl;

  const FakeCard({
    required this.id,
    required this.name,
    required this.rarity,
    required this.scaleLabel,
    required this.description,
    required this.artUrl,
  });
}

class FakeDeck {
  final String id;
  final String name;
  final List<FakeCard> cards;

  const FakeDeck({required this.id, required this.name, required this.cards});

  FakeCard? cardById(String? id) =>
      cards.where((card) => card.id == id).firstOrNull;
}

FakeDeck? fakeDeckById(String? id) =>
    fakeDecks.where((deck) => deck.id == id).firstOrNull;

const _art = 'https://takadev1cv.blob.core.windows.net/card-art';

const fakeDecks = [
  FakeDeck(id: 'meridian-01', name: 'Meridian', cards: [
    FakeCard(
      id: 'gnomon',
      name: 'Gnomon',
      rarity: FakeRarity.common,
      scaleLabel: 'Small',
      description: 'Casts a shadow long enough to read a heading from.',
      artUrl: '$_art/meridian-01/gnomon.jpg',
    ),
    FakeCard(
      id: 'vernier',
      name: 'Vernier',
      rarity: FakeRarity.common,
      scaleLabel: 'Small',
      description: 'Nested sleeves that slide to split a reading finer.',
      artUrl: '$_art/meridian-01/vernier.jpg',
    ),
    FakeCard(
      id: 'lodestone',
      name: 'Lodestone',
      rarity: FakeRarity.common,
      scaleLabel: 'Small',
      description: 'Drags a haze of iron filings wherever it turns.',
      artUrl: '$_art/meridian-01/lodestone.jpg',
    ),
    FakeCard(
      id: 'astrolabe',
      name: 'Astrolabe',
      rarity: FakeRarity.uncommon,
      scaleLabel: 'Medium',
      description: 'Unfolds into a ring wider than itself to take one '
          'reading, then folds away.',
      artUrl: '$_art/meridian-01/astrolabe.jpg',
    ),
    FakeCard(
      id: 'quadrant',
      name: 'Quadrant',
      rarity: FakeRarity.uncommon,
      scaleLabel: 'Medium',
      description: 'A quarter arc that measures the angle to anything it can '
          'see.',
      artUrl: '$_art/meridian-01/quadrant.jpg',
    ),
    FakeCard(
      id: 'orrery',
      name: 'The Orrery',
      rarity: FakeRarity.rare,
      scaleLabel: 'Capital',
      description: 'Carries a working model of the system it is crossing.',
      artUrl: '$_art/meridian-01/orrery.jpg',
    ),
  ]),
  FakeDeck(id: 'cinder-01', name: 'Cinder', cards: [
    FakeCard(
      id: 'flint',
      name: 'Flint',
      rarity: FakeRarity.common,
      scaleLabel: 'Small',
      description: 'Three striker arms that throw sparks to start something '
          'bigger.',
      artUrl: '$_art/cinder-01/flint.jpg',
    ),
    FakeCard(
      id: 'wick',
      name: 'Wick',
      rarity: FakeRarity.common,
      scaleLabel: 'Small',
      description: 'Burns slowly and on purpose.',
      artUrl: '$_art/cinder-01/wick.jpg',
    ),
    FakeCard(
      id: 'rasp',
      name: 'Rasp',
      rarity: FakeRarity.common,
      scaleLabel: 'Small',
      description: 'Strips plating off anything it is dragged along.',
      artUrl: '$_art/cinder-01/rasp.jpg',
    ),
    FakeCard(
      id: 'scorch',
      name: 'Scorch',
      rarity: FakeRarity.uncommon,
      scaleLabel: 'Medium',
      description: 'Leaves a blackened wake it never outruns.',
      artUrl: '$_art/cinder-01/scorch.jpg',
    ),
    FakeCard(
      id: 'kiln',
      name: 'Kiln',
      rarity: FakeRarity.uncommon,
      scaleLabel: 'Medium',
      description: 'Holds a fire hot enough to reshape what it carries.',
      artUrl: '$_art/cinder-01/kiln.jpg',
    ),
    FakeCard(
      id: 'crucible',
      name: 'The Crucible',
      rarity: FakeRarity.rare,
      scaleLabel: 'Capital',
      description: 'Everything it takes in comes out as something else.',
      artUrl: '$_art/cinder-01/crucible.jpg',
    ),
  ]),
];
