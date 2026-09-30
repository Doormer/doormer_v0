import 'dart:async';

import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/features/collection/di/collection_module.dart';
import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/domain/entity/collection.dart';
import 'package:doormer/src/features/collection/domain/entity/deck.dart';
import 'package:doormer/src/features/collection/domain/entity/deck_progress.dart';
import 'package:doormer/src/features/collection/domain/entity/draw_outcome.dart';
import 'package:doormer/src/features/collection/domain/entity/holding.dart';
import 'package:doormer/src/features/collection/domain/repository/collection_repository.dart';
import 'package:doormer/src/features/collection/presentation/atoms/collectible_card_atom.dart';
import 'package:doormer/src/features/collection/presentation/molecules/card_tile_molecule.dart';
import 'package:doormer/src/features/collection/presentation/molecules/deck_row_molecule.dart';
import 'package:doormer/src/features/collection/presentation/organisms/card_detail_organism.dart';
import 'package:doormer/src/features/collection/presentation/organisms/card_grid_organism.dart';
import 'package:doormer/src/features/collection/presentation/organisms/card_reveal_organism.dart';
import 'package:doormer/src/features/collection/presentation/organisms/deck_list_organism.dart';
import 'package:doormer/src/features/collection/presentation/organisms/empty_deck_organism.dart';
import 'package:doormer/src/features/collection/presentation/pages/collection_page.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

CollectibleCard _card(String id, String name, Rarity rarity) {
  const scaleLabels = {
    Rarity.common: 'Small',
    Rarity.uncommon: 'Medium',
    Rarity.rare: 'Capital',
  };
  const standardShatterQuarks = {
    Rarity.common: 5,
    Rarity.uncommon: 11,
    Rarity.rare: 19,
  };
  return CollectibleCard(
    id: id,
    name: name,
    rarity: rarity,
    scaleLabel: scaleLabels[rarity]!,
    // Never loads in a test: the art area shows its dim panel instead.
    artUrl: 'https://example.test/$id.jpg',
    standardShatterQuarks: standardShatterQuarks[rarity]!,
    specialShatterQuarks: standardShatterQuarks[rarity]! * 2,
    description: '$name.',
  );
}

final _decks = {
  for (final deck in [
    Deck(id: 'meridian', name: 'Meridian', drawCost: 40, cards: [
      _card('gnomon', 'Gnomon', Rarity.common),
      _card('vernier', 'Vernier', Rarity.common),
      _card('lodestone', 'Lodestone', Rarity.common),
      _card('astrolabe', 'Astrolabe', Rarity.uncommon),
      _card('quadrant', 'Quadrant', Rarity.uncommon),
      _card('orrery', 'The Orrery', Rarity.rare),
    ]),
    Deck(id: 'cinder', name: 'Cinder', drawCost: 40, cards: [
      _card('flint', 'Flint', Rarity.common),
      _card('wick', 'Wick', Rarity.common),
      _card('rasp', 'Rasp', Rarity.common),
      _card('scorch', 'Scorch', Rarity.uncommon),
      _card('kiln', 'Kiln', Rarity.uncommon),
      _card('crucible', 'The Crucible', Rarity.rare),
    ]),
  ])
    deck.id: deck,
};

final _noConnection =
    NetworkFailure("We couldn't connect. Check your connection and try again.");

CollectibleCard _cardOf(String cardId) => _decks.values
    .expand((deck) => deck.cards)
    .firstWhere((card) => card.id == cardId);

/// The server, played in memory. It starts where the bundled mock used to:
/// 600 quarks, 4 of Meridian's 6 cards, and nothing in Cinder. Each deck
/// draws in a fixed order, so every journey knows what comes next. A test can
/// make the next load fail, or hold back a draw's answer.
class _InMemoryCollectionRepository implements CollectionRepository {
  static const _drawOrder = {
    'meridian': [
      // An upgrade: The Orrery is held, but only as a standard copy.
      ('orrery', CardVariant.special),
      // A new card.
      ('quadrant', CardVariant.standard),
      // A duplicate.
      ('gnomon', CardVariant.standard),
    ],
    'cinder': [('flint', CardVariant.standard)],
  };

  /// When set, the next load fails with it.
  Failure? failNextLoadWith;

  /// When set, every draw waits for it before it answers.
  Future<void>? drawWaitsFor;

  /// When set, the next shatter fails with it.
  Failure? failNextShatterWith;

  void _failLoadIfAsked() {
    final failure = failNextLoadWith;
    failNextLoadWith = null;
    if (failure != null) throw failure;
  }

  int _quarkBalance = 600;
  final Map<String, int> _drawsMade = {};
  final Map<String, Holding> _holdings = {
    'gnomon': _holding('gnomon', standard: 3),
    'vernier': _holding('vernier', standard: 1),
    'astrolabe': _holding('astrolabe', standard: 1, special: 1),
    'orrery': _holding('orrery', standard: 1),
  };

  static Holding _holding(String cardId, {int standard = 0, int special = 0}) =>
      Holding(
        card: _cardOf(cardId),
        standardCopies: standard,
        specialCopies: special,
      );

  Collection _collectionOf(String deckId) {
    final deck = _decks[deckId]!;
    return Collection(deck: deck, holdingsByCardId: {
      for (final card in deck.cards)
        if (_holdings.containsKey(card.id)) card.id: _holdings[card.id]!,
    });
  }

  /// Adds [count] copies of [variant]; a negative [count] removes them.
  Holding _addCopies(String cardId, CardVariant variant, int count) {
    final before = _holdings[cardId];
    return _holdings[cardId] = _holding(
      cardId,
      standard: (before?.standardCopies ?? 0) +
          (variant == CardVariant.standard ? count : 0),
      special: (before?.specialCopies ?? 0) +
          (variant == CardVariant.special ? count : 0),
    );
  }

  @override
  Future<({int quarkBalance, List<DeckProgress> decks})> loadDecks() async {
    _failLoadIfAsked();
    return (
      quarkBalance: _quarkBalance,
      decks: [
        for (final deck in _decks.values)
          DeckProgress(
            deckId: deck.id,
            name: deck.name,
            cardsHeld: _collectionOf(deck.id).cardsHeld,
            cardsTotal: deck.size,
          ),
      ],
    );
  }

  @override
  Future<({int quarkBalance, Collection collection})> loadCollection(
    String deckId,
  ) async {
    _failLoadIfAsked();
    return (quarkBalance: _quarkBalance, collection: _collectionOf(deckId));
  }

  @override
  Future<({int quarkBalance, DrawOutcome outcome})> draw(String deckId) async {
    final wait = drawWaitsFor;
    if (wait != null) await wait;

    final order = _drawOrder[deckId]!;
    final drawsMade = _drawsMade[deckId] ?? 0;
    _drawsMade[deckId] = drawsMade + 1;
    final (cardId, variant) = order[drawsMade % order.length];

    final before = _holdings[cardId];
    final result = before == null
        ? DrawResult.newCard
        : variant == CardVariant.special && !before.hasSpecial
            ? DrawResult.upgrade
            : DrawResult.duplicate;
    final after = _addCopies(cardId, variant, 1);
    _quarkBalance -= _decks[deckId]!.drawCost;
    return (
      quarkBalance: _quarkBalance,
      outcome: DrawOutcome(
        card: after.card,
        variant: variant,
        result: result,
        copiesAfter: after.totalCopies,
      ),
    );
  }

  @override
  Future<({int quarkBalance, int standardCopies, int specialCopies})>
      shatterCopy(String deckId, String cardId, CardVariant variant) async {
    final failure = failNextShatterWith;
    failNextShatterWith = null;
    if (failure != null) throw failure;
    final after = _addCopies(cardId, variant, -1);
    _quarkBalance += after.card.shatterQuarksFor(variant);
    return (
      quarkBalance: _quarkBalance,
      standardCopies: after.standardCopies,
      specialCopies: after.specialCopies,
    );
  }
}

Widget _app() => ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => const MaterialApp(home: CollectionPage()),
    );

Future<void> _pumpPhone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 690);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app());

  // Not pumpAndSettle while loading: the spinner schedules frames forever, so
  // settling is impossible until the deck list has arrived. Pump the async
  // gap first, then settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

Future<void> _openDeck(WidgetTester tester, String name) async {
  await tester.tap(find.widgetWithText(DeckRowMolecule, name));
  await tester.pumpAndSettle();
}

/// Pumps the reveal through to its end.
///
/// Not `pumpAndSettle`: a rare draw spins its rays continuously by design, so
/// there is never a frame with nothing scheduled and settling would hang.
Future<void> _drawAndDismiss(WidgetTester tester) async {
  await tester.tap(find.textContaining('Draw a card').first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1700));
  await tester.tap(find.byType(CardRevealOrganism));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// The journey, end to end, against the real DI container, bloc and widgets.
/// Only the repository is replaced, by one that plays the server in memory;
/// the data source, the response models and the repository have their own
/// tests.
void main() {
  late _InMemoryCollectionRepository server;

  setUp(() async {
    // A fresh container per test, so one test's draws never carry into the
    // next. `reset` is async — not awaiting it lets the wipe land after the
    // re-registration.
    await GetIt.instance.reset();
    initCollectionModule();

    await GetIt.instance.unregister<CollectionRepository>();
    server = _InMemoryCollectionRepository();
    GetIt.instance.registerSingleton<CollectionRepository>(server);
  });

  tearDown(() async => GetIt.instance.reset());

  testWidgets('opens on the deck list, not on a deck', (tester) async {
    await _pumpPhone(tester);

    expect(find.byType(DeckListOrganism), findsOneWidget);
    expect(find.text('Meridian'), findsOneWidget);
    expect(find.text('Cinder'), findsOneWidget);
    expect(find.byType(CardGridOrganism), findsNothing,
        reason: 'the list is the home; cards are one level down');
  });

  testWidgets('tapping a deck shows its held cards and the draw button',
      (tester) async {
    await _pumpPhone(tester);
    await _openDeck(tester, 'Meridian');

    expect(find.byType(CardGridOrganism), findsOneWidget);
    // The student holds 4 of Meridian's 6 cards.
    expect(find.byType(CardTileMolecule), findsNWidgets(4));
    expect(find.textContaining('Draw a card'), findsOneWidget);
  });

  testWidgets('a deck holding nothing shows the empty state, never a bare grid',
      (tester) async {
    await _pumpPhone(tester);
    await _openDeck(tester, 'Cinder');

    expect(find.byType(EmptyDeckOrganism), findsOneWidget);
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('6 cards to find'), findsOneWidget);
    expect(find.byType(CardTileMolecule), findsNothing);
  });

  testWidgets('drawing reveals a card, and dismissing returns to the deck',
      (tester) async {
    await _pumpPhone(tester);
    await _openDeck(tester, 'Meridian');

    await tester.tap(find.textContaining('Draw a card'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1700));

    expect(find.byType(CardRevealOrganism), findsOneWidget);
    // Meridian's first draw is a special copy of The Orrery, which is already
    // held, so this is an upgrade rather than a new card.
    expect(find.text('Now special'), findsOneWidget);

    await tester.tap(find.byType(CardRevealOrganism));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CardRevealOrganism), findsNothing,
        reason: 'a reveal must not be able to stick on screen');
    // An upgrade adds a printing, not a card, so the grid still holds 4.
    expect(find.byType(CardTileMolecule), findsNWidgets(4));

    // The second draw is Quadrant, which is genuinely new — that is what grows
    // the grid.
    await _drawAndDismiss(tester);
    expect(find.byType(CardTileMolecule), findsNWidgets(5));
  });

  testWidgets('leaving the collection and coming back keeps what was drawn',
      (tester) async {
    await _pumpPhone(tester);
    await _openDeck(tester, 'Meridian');
    // Two draws: the first upgrades the rare, the second adds Quadrant.
    await _drawAndDismiss(tester);
    await _drawAndDismiss(tester);
    expect(find.byType(CardTileMolecule), findsNWidgets(5));

    // Remount the page, as navigating away and back would. The new page reads
    // everything again, and the server still has both draws.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    await _openDeck(tester, 'Meridian');

    expect(find.byType(CardTileMolecule), findsNWidgets(5),
        reason: 'the drawn card survived the remount');
    expect(find.textContaining('520 quarks'), findsOneWidget,
        reason: 'and so did the quarks the two draws cost');
  });

  testWidgets(
      'the quark balance is visible, so quarks are never spent invisibly',
      (tester) async {
    await _pumpPhone(tester);
    expect(find.textContaining('600 quarks'), findsOneWidget);

    await _openDeck(tester, 'Meridian');
    expect(find.textContaining('600 quarks'), findsOneWidget,
        reason:
            'the quark balance must follow the student to where they spend');
  });

  testWidgets('every reveal pairs its headline with a supporting line',
      (tester) async {
    await _pumpPhone(tester);
    await _openDeck(tester, 'Meridian');

    // 1. Upgrade — the mockup reassures that the plain copy survives.
    await tester.tap(find.textContaining('Draw a card').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1700));
    expect(find.text('Now special'), findsOneWidget);
    expect(find.text('You keep the standard one.'), findsOneWidget);
    await tester.tap(find.byType(CardRevealOrganism));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 2. New card — deck progress, in digits.
    await tester.tap(find.textContaining('Draw a card').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1700));
    expect(find.text('A new one'), findsOneWidget);
    expect(find.text('Meridian is 5 of 6'), findsOneWidget);
    await tester.tap(find.byType(CardRevealOrganism));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 3. Duplicate — what the spare is worth. Gnomon is common, so 5.
    await tester.tap(find.textContaining('Draw a card').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1700));
    expect(find.text('Another one'), findsOneWidget);
    expect(find.text('Shatter one for 5 quarks'), findsOneWidget);
  });

  testWidgets('an upgrade is still visible after the reveal is dismissed',
      (tester) async {
    await _pumpPhone(tester);
    await _openDeck(tester, 'Meridian');

    // The Orrery already has a plain copy; the first draw upgrades it.
    Iterable<CollectibleCardAtom> specials() => tester
        .widgetList<CollectibleCardAtom>(find.byType(CollectibleCardAtom))
        .where((c) => c.isSpecial);

    final before = specials().length;
    await _drawAndDismiss(tester);

    expect(specials().length, greaterThan(before),
        reason: '"Now special" must leave something behind in the grid');
  });

  testWidgets('tapping a card opens its detail, and it can be closed',
      (tester) async {
    await _pumpPhone(tester);
    await _openDeck(tester, 'Meridian');

    await tester.tap(find.byType(CardTileMolecule).first);
    await tester.pumpAndSettle();

    expect(find.byType(CardDetailOrganism), findsOneWidget);

    await tester.tap(find.byKey(const Key('card-detail-close')));
    await tester.pumpAndSettle();

    expect(find.byType(CardDetailOrganism), findsNothing,
        reason: 'the detail must not be a dead end');
  });

  testWidgets('shattering a spare pays its quarks, and the window stays open',
      (tester) async {
    await _pumpPhone(tester);
    await _openDeck(tester, 'Meridian');

    // Gnomon comes first in the deck, held three times.
    await tester.tap(find.byType(CardTileMolecule).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shatter one'));
    await tester.pumpAndSettle();

    final window = find.byType(CardDetailOrganism);
    expect(window, findsOneWidget,
        reason: 'the next spare can be shattered straight away');
    expect(
        find.descendant(of: window, matching: find.text('2')), findsOneWidget,
        reason: 'Held drops from 3 to 2');
    expect(find.text('605 quarks'), findsNWidgets(2),
        reason: 'a common spare is worth 5 quarks, and the window and the '
            'page behind it both say so');
    final gnomon =
        tester.widget<CardTileMolecule>(find.byType(CardTileMolecule).first);
    expect(gnomon.holding.totalCopies, 2);
  });

  testWidgets('a shatter that fails says why in the window', (tester) async {
    await _pumpPhone(tester);
    await _openDeck(tester, 'Meridian');
    server.failNextShatterWith = _noConnection;

    await tester.tap(find.byType(CardTileMolecule).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shatter one'));
    await tester.pumpAndSettle();

    final window = find.byType(CardDetailOrganism);
    expect(
        find.descendant(of: window, matching: find.text(_noConnection.message)),
        findsOneWidget);
    expect(find.text('600 quarks'), findsNWidgets(2),
        reason: 'nothing broke, so nothing was paid');
  });

  testWidgets('a failed shatter is not repeated when the window opens again',
      (tester) async {
    await _pumpPhone(tester);
    await _openDeck(tester, 'Meridian');
    server.failNextShatterWith = _noConnection;
    await tester.tap(find.byType(CardTileMolecule).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shatter one'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('card-detail-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CardTileMolecule).first);
    await tester.pumpAndSettle();

    final window = find.byType(CardDetailOrganism);
    expect(
        find.descendant(of: window, matching: find.text(_noConnection.message)),
        findsNothing,
        reason: 'the failure belongs to the window that was closed');
    expect(find.descendant(of: window, matching: find.text('+5 quarks')),
        findsOneWidget);
  });

  testWidgets('going back from a deck returns to the list', (tester) async {
    await _pumpPhone(tester);
    await _openDeck(tester, 'Meridian');
    expect(find.byType(CardGridOrganism), findsOneWidget);

    await tester.tap(find.text('Decks'));
    await tester.pumpAndSettle();

    expect(find.byType(DeckListOrganism), findsOneWidget);
    expect(find.byType(CardGridOrganism), findsNothing);
  });

  testWidgets('when the decks cannot load, Retry loads them', (tester) async {
    server.failNextLoadWith = _noConnection;
    await _pumpPhone(tester);

    expect(find.text(_noConnection.message), findsOneWidget);
    expect(find.byType(DeckListOrganism), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.byType(DeckListOrganism), findsOneWidget);
    expect(find.textContaining('600 quarks'), findsOneWidget);
  });

  testWidgets('when a deck cannot load, Retry opens it again', (tester) async {
    await _pumpPhone(tester);
    server.failNextLoadWith = _noConnection;
    await _openDeck(tester, 'Meridian');

    expect(find.text(_noConnection.message), findsOneWidget);
    expect(find.byType(CardGridOrganism), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.byType(CardTileMolecule), findsNWidgets(4));
  });

  testWidgets('the draw button spins until the drawn card is ready',
      (tester) async {
    await _pumpPhone(tester);
    await _openDeck(tester, 'Meridian');
    final answer = Completer<void>();
    server.drawWaitsFor = answer.future;
    AppButtonAtom drawButton() =>
        tester.widget<AppButtonAtom>(find.byType(AppButtonAtom));

    await tester.tap(find.textContaining('Draw a card'));
    await tester.pump();
    expect(drawButton().isLoading, isTrue);

    answer.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1700));
    expect(find.byType(CardRevealOrganism), findsOneWidget);

    await tester.tap(find.byType(CardRevealOrganism));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(drawButton().isLoading, isFalse);
  });
}
