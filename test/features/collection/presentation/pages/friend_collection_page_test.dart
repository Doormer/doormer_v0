import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/domain/entity/collection.dart';
import 'package:doormer/src/features/collection/domain/entity/deck.dart';
import 'package:doormer/src/features/collection/domain/entity/deck_progress.dart';
import 'package:doormer/src/features/collection/domain/entity/holding.dart';
import 'package:doormer/src/features/collection/domain/repository/friend_collection_repository.dart';
import 'package:doormer/src/features/collection/domain/usecase/load_friend_collection_usecase.dart';
import 'package:doormer/src/features/collection/domain/usecase/load_friend_decks_usecase.dart';
import 'package:doormer/src/features/collection/presentation/bloc/friend_collection_bloc.dart';
import 'package:doormer/src/features/collection/presentation/molecules/card_tile_molecule.dart';
import 'package:doormer/src/features/collection/presentation/organisms/card_detail_organism.dart';
import 'package:doormer/src/features/collection/presentation/pages/friend_collection_page.dart';
import 'package:doormer/src/shared/design/atomic/atoms/level_icons_atom.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _sam = FriendSummary(friendId: '42', nickname: 'Sam');

/// Sam at level 6, as the friends list knows him. His collection's page shows
/// no level, even if it gets one.
const _samAtLevel6 = FriendSummary(
  friendId: '42',
  nickname: 'Sam',
  level: Level(number: 6, suns: 0, moons: 1, stars: 2),
);

CollectibleCard _card(String id, String name) => CollectibleCard(
      id: id,
      name: name,
      rarity: Rarity.common,
      scaleLabel: 'Small',
      artUrl: 'https://example.test/$id.png',
      standardShatterQuarks: 0,
      specialShatterQuarks: 0,
      description: 'A card of $name.',
    );

final _gnomon = _card('gnomon', 'Gnomon');
final _vernier = _card('vernier', 'Vernier');

/// Sam's collection: one Meridian card, held twice, and nothing from Cinder.
class _FakeRepository implements FriendCollectionRepository {
  Object? decksError;

  /// The friend, as the API's answers name them.
  FriendSummary friend = _sam;

  @override
  Future<({FriendSummary friend, List<DeckProgress> decks})> loadDecks(
      String friendId) async {
    final error = decksError;
    decksError = null;
    if (error != null) throw error;
    return (
      friend: friend,
      decks: const [
        DeckProgress(
            deckId: 'cinder-01', name: 'Cinder', cardsHeld: 0, cardsTotal: 6),
        DeckProgress(
            deckId: 'meridian-01',
            name: 'Meridian',
            cardsHeld: 1,
            cardsTotal: 2),
      ],
    );
  }

  @override
  Future<({FriendSummary friend, Collection collection})> loadCollection(
      String friendId, String deckId) async {
    final deck = deckId == 'meridian-01'
        ? Deck(
            id: deckId,
            name: 'Meridian',
            drawCost: 0,
            cards: [_gnomon, _vernier])
        : Deck(id: deckId, name: 'Cinder', drawCost: 0, cards: const []);
    return (
      friend: friend,
      collection: Collection(
        deck: deck,
        holdingsByCardId: {
          if (deckId == 'meridian-01')
            'gnomon':
                Holding(card: _gnomon, standardCopies: 2, specialCopies: 0),
        },
      ),
    );
  }
}

void main() {
  setUpAll(AppLogger.disable);

  late _FakeRepository repository;

  setUp(() {
    repository = _FakeRepository();
    serviceLocator.registerFactory<FriendCollectionBloc>(
      () => FriendCollectionBloc(
        loadDecks: LoadFriendDecksUseCase(repository),
        loadCollection: LoadFriendCollectionUseCase(repository),
      ),
    );
  });

  tearDown(() => serviceLocator.reset());

  Future<GoRouter> pumpCollection(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/profile/friends/42/cards',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (_, __) => const Scaffold(body: Text('Profile page')),
          routes: [
            GoRoute(
              path: 'friends/:friendId/cards',
              builder: (_, state) => FriendCollectionPage(
                friendId: state.pathParameters['friendId']!,
                friend: const FriendSummary(friendId: '42', nickname: 'Sam'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp.router(
        theme: AppTheme.dark,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> openMeridian(WidgetTester tester) async {
    await tester.tap(find.text('Meridian'));
    await tester.pumpAndSettle();
  }

  testWidgets("is headed with Sam's picture and name, over Sam's decks",
      (tester) async {
    await pumpCollection(tester);

    expect(find.text("Sam's cards"), findsOneWidget);
    expect(find.text('S'), findsOneWidget, reason: "Sam's first letter");
    expect(find.text('Cinder'), findsOneWidget);
    expect(find.text('Meridian'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('New'), findsNothing,
        reason: "Sam's untouched deck isn't new to the student");
  });

  testWidgets('a deck shows the cards Sam holds, with no Draw', (tester) async {
    await pumpCollection(tester);

    await openMeridian(tester);

    expect(find.text('1 of 2 held'), findsOneWidget);
    expect(find.byType(CardTileMolecule), findsOneWidget);
    expect(find.textContaining('Draw'), findsNothing);
    expect(find.textContaining('quark'), findsNothing);
  });

  testWidgets("a card opens its detail, with no Shatter and no quarks",
      (tester) async {
    await pumpCollection(tester);
    await openMeridian(tester);

    await tester.tap(find.byType(CardTileMolecule));
    await tester.pumpAndSettle();

    expect(find.byType(CardDetailOrganism), findsOneWidget);
    expect(find.text('Shatter one'), findsNothing);
    expect(find.textContaining('quark'), findsNothing);

    await tester.tap(find.byKey(const Key('card-detail-close')));
    await tester.pumpAndSettle();
    expect(find.byType(CardDetailOrganism), findsNothing);
  });

  testWidgets('a deck Sam has nothing from says so', (tester) async {
    await pumpCollection(tester);

    await tester.tap(find.text('Cinder'));
    await tester.pumpAndSettle();

    expect(find.text('No cards from this deck yet.'), findsOneWidget);
  });

  testWidgets('Decks goes back to the deck list', (tester) async {
    await pumpCollection(tester);
    await openMeridian(tester);

    await tester.tap(find.byKey(const Key('friend_deck_back')));
    await tester.pumpAndSettle();

    expect(find.text('Cinder'), findsOneWidget);
    expect(find.byType(CardTileMolecule), findsNothing);
  });

  testWidgets("a load that fails says Sam's cards couldn't load, and retries",
      (tester) async {
    repository.decksError = NetworkFailure();

    await pumpCollection(tester);
    expect(find.text("We couldn't load Sam's cards."), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Meridian'), findsOneWidget);
  });

  testWidgets('not friends any more says so, and goes back to Profile',
      (tester) async {
    repository.decksError =
        RefusedFailure(404, "We couldn't find that friend.");

    final router = await pumpCollection(tester);

    expect(find.text("We couldn't find that friend."), findsOneWidget);
    expect(find.text('Profile page'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/profile');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('the back arrow goes back to Profile', (tester) async {
    await pumpCollection(tester);

    await tester.tap(find.byKey(const Key('page_back')));
    await tester.pumpAndSettle();

    expect(find.text('Profile page'), findsOneWidget);
  });

  testWidgets('shows no level, even for a friend who has one', (tester) async {
    repository.friend = _samAtLevel6;

    await pumpCollection(tester);

    expect(find.text("Sam's cards"), findsOneWidget);
    expect(find.byType(LevelIconsAtom), findsNothing);
    expect(find.textContaining('Level'), findsNothing);
  });
}
