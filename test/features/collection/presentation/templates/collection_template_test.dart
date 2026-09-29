import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/domain/entity/collection.dart';
import 'package:doormer/src/features/collection/domain/entity/deck.dart';
import 'package:doormer/src/features/collection/domain/entity/deck_progress.dart';
import 'package:doormer/src/features/collection/domain/entity/holding.dart';
import 'package:doormer/src/features/collection/presentation/organisms/card_grid_organism.dart';
import 'package:doormer/src/features/collection/presentation/organisms/deck_list_organism.dart';
import 'package:doormer/src/features/collection/presentation/organisms/empty_deck_organism.dart';
import 'package:doormer/src/features/collection/presentation/templates/collection_template.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _gnomon = CollectibleCard(
  id: 'gnomon',
  name: 'Gnomon',
  rarity: Rarity.common,
  scaleLabel: 'Small',
  artUrl: 'https://example.test/gnomon.jpg',
  standardShatterQuarks: 5,
  specialShatterQuarks: 10,
  description: 'd',
);

const _flint = CollectibleCard(
  id: 'flint',
  name: 'Flint',
  rarity: Rarity.common,
  scaleLabel: 'Small',
  artUrl: 'https://example.test/flint.jpg',
  standardShatterQuarks: 5,
  specialShatterQuarks: 10,
  description: 'd',
);

const _decks = [
  DeckProgress(
      deckId: 'meridian', name: 'Meridian', cardsHeld: 1, cardsTotal: 1),
  DeckProgress(deckId: 'cinder', name: 'Cinder', cardsHeld: 0, cardsTotal: 6),
];

const _meridian = Collection(
  deck: Deck(id: 'meridian', name: 'Meridian', drawCost: 40, cards: [_gnomon]),
  holdingsByCardId: {
    'gnomon': Holding(card: _gnomon, standardCopies: 1, specialCopies: 0),
  },
);

/// Cinder, holding nothing yet.
const _cinder = Collection(
  deck: Deck(id: 'cinder', name: 'Cinder', drawCost: 40, cards: [_flint]),
  holdingsByCardId: {},
);

CollectionTemplate _template({
  int quarkBalance = 120,
  String? selectedDeckId,
  Collection? collection,
  String? deckErrorMessage,
  bool isDrawing = false,
  void Function(String deckId)? onSelectDeck,
}) =>
    CollectionTemplate(
      quarkBalance: quarkBalance,
      decks: _decks,
      selectedDeckId: selectedDeckId,
      collection: collection,
      deckErrorMessage: deckErrorMessage,
      isDrawing: isDrawing,
      onSelectDeck: onSelectDeck ?? (_) {},
      onCloseDeck: () {},
      onDraw: () {},
      onCardTap: (_) {},
    );

const _phone = Size(390, 800);
const _wideWindow = Size(1200, 900);

Future<void> _pumpAt(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (context, _) => MaterialApp(home: child),
  ));
  await tester.pump();
}

void main() {
  testWidgets('a phone with no deck open shows the list and no grid',
      (tester) async {
    await _pumpAt(tester, _phone, _template());
    expect(find.byType(DeckListOrganism), findsOneWidget);
    expect(find.byType(CardGridOrganism), findsNothing);
    expect(find.text('2 decks'), findsOneWidget);
    expect(find.text('120 quarks'), findsOneWidget);
  });

  testWidgets('a phone with a deck open shows the grid and not the list',
      (tester) async {
    await _pumpAt(tester, _phone,
        _template(selectedDeckId: 'meridian', collection: _meridian));
    expect(find.byType(CardGridOrganism), findsOneWidget);
    expect(find.byType(DeckListOrganism), findsNothing);
    expect(find.text('1 of 1 held'), findsOneWidget);
    expect(find.text('Draw a card · 40'), findsOneWidget);
  });

  testWidgets('a wide window shows the rail and the deck together',
      (tester) async {
    await _pumpAt(tester, _wideWindow,
        _template(selectedDeckId: 'meridian', collection: _meridian));
    expect(find.byType(DeckListOrganism), findsOneWidget);
    expect(find.byType(CardGridOrganism), findsOneWidget);
  });

  testWidgets('the template owns exactly one Scaffold', (tester) async {
    await _pumpAt(tester, _wideWindow,
        _template(selectedDeckId: 'meridian', collection: _meridian));
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('a deck still loading shows its name and a spinner',
      (tester) async {
    await _pumpAt(tester, _phone, _template(selectedDeckId: 'meridian'));
    expect(find.text('Meridian'), findsOneWidget,
        reason: 'the name comes from the deck list, which has already loaded');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(CardGridOrganism), findsNothing);
  });

  testWidgets('a deck that could not load says why, and Retry opens it again',
      (tester) async {
    final opened = <String>[];
    await _pumpAt(
        tester,
        _phone,
        _template(
          selectedDeckId: 'meridian',
          deckErrorMessage: 'Something went wrong. Try again.',
          onSelectDeck: opened.add,
        ));
    expect(find.text('Something went wrong. Try again.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(CardGridOrganism), findsNothing);

    await tester.tap(find.text('Retry'));
    expect(opened, ['meridian']);
  });

  testWidgets('while a draw is in flight the draw button spins',
      (tester) async {
    await _pumpAt(
        tester,
        _phone,
        _template(
          selectedDeckId: 'meridian',
          collection: _meridian,
          isDrawing: true,
        ));
    expect(tester.widget<AppButtonAtom>(find.byType(AppButtonAtom)).isLoading,
        isTrue);
  });

  testWidgets('while a draw is in flight the empty deck\'s draw button spins',
      (tester) async {
    await _pumpAt(
        tester,
        _phone,
        _template(
          selectedDeckId: 'cinder',
          collection: _cinder,
          isDrawing: true,
        ));
    expect(find.byType(EmptyDeckOrganism), findsOneWidget);
    expect(tester.widget<AppButtonAtom>(find.byType(AppButtonAtom)).isLoading,
        isTrue);
  });

  testWidgets('a draw the student cannot afford says how far short they are',
      (tester) async {
    await _pumpAt(
        tester,
        _phone,
        _template(
          quarkBalance: 15,
          selectedDeckId: 'meridian',
          collection: _meridian,
        ));
    expect(find.text('25 more quarks to draw'), findsOneWidget);
    expect(tester.widget<AppButtonAtom>(find.byType(AppButtonAtom)).onPressed,
        isNull);
  });
}
