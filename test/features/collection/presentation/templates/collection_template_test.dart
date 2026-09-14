import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/domain/entity/collection.dart';
import 'package:doormer/src/features/collection/domain/entity/deck.dart';
import 'package:doormer/src/features/collection/domain/entity/holding.dart';
import 'package:doormer/src/features/collection/presentation/organisms/card_grid_organism.dart';
import 'package:doormer/src/features/collection/presentation/organisms/deck_list_organism.dart';
import 'package:doormer/src/features/collection/presentation/templates/collection_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _gnomon = CollectibleCard(
  id: 'gnomon',
  name: 'Gnomon',
  deckId: 'meridian',
  rarity: Rarity.common,
  scaleLabel: 'Small',
  artAsset: 'assets/cards/meridian/gnomon.png',
  description: 'd',
);

Collection _collection() => const Collection(
      decks: [
        Deck(id: 'meridian', name: 'Meridian', cards: [_gnomon]),
        Deck(id: 'cinder', name: 'Cinder', cards: []),
      ],
      holdingsByCardId: {
        'gnomon': Holding(
          card: _gnomon,
          standardCopies: 1,
          specialCopies: 0,
        ),
      },
      walletPoints: 120,
      drawCost: 40,
    );

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
    await _pumpAt(tester, const Size(390, 800), CollectionTemplate(
      collection: _collection(),
      selectedDeckId: null,
      onSelectDeck: (_) {},
      onCloseDeck: () {},
      onDraw: () {},
      onCardTap: (_) {},
    ));
    expect(find.byType(DeckListOrganism), findsOneWidget);
    expect(find.byType(CardGridOrganism), findsNothing);
  });

  testWidgets('a phone with a deck open shows the grid and not the list',
      (tester) async {
    await _pumpAt(tester, const Size(390, 800), CollectionTemplate(
      collection: _collection(),
      selectedDeckId: 'meridian',
      onSelectDeck: (_) {},
      onCloseDeck: () {},
      onDraw: () {},
      onCardTap: (_) {},
    ));
    expect(find.byType(CardGridOrganism), findsOneWidget);
    expect(find.byType(DeckListOrganism), findsNothing);
  });

  testWidgets('a wide window shows the rail and the deck together',
      (tester) async {
    await _pumpAt(tester, const Size(1200, 900), CollectionTemplate(
      collection: _collection(),
      selectedDeckId: 'meridian',
      onSelectDeck: (_) {},
      onCloseDeck: () {},
      onDraw: () {},
      onCardTap: (_) {},
    ));
    expect(find.byType(DeckListOrganism), findsOneWidget);
    expect(find.byType(CardGridOrganism), findsOneWidget);
  });

  testWidgets('the template owns exactly one Scaffold', (tester) async {
    await _pumpAt(tester, const Size(1200, 900), CollectionTemplate(
      collection: _collection(),
      selectedDeckId: 'meridian',
      onSelectDeck: (_) {},
      onCloseDeck: () {},
      onDraw: () {},
      onCardTap: (_) {},
    ));
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
