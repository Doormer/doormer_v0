import 'dart:convert';
import 'dart:io';

import 'package:doormer/src/features/collection/data/datasource/collection_local_datasource.dart';
import 'package:doormer/src/features/collection/di/collection_module.dart';
import 'package:doormer/src/features/collection/presentation/molecules/card_tile_molecule.dart';
import 'package:doormer/src/features/collection/presentation/molecules/deck_row_molecule.dart';
import 'package:doormer/src/features/collection/presentation/organisms/card_detail_organism.dart';
import 'package:doormer/src/features/collection/presentation/organisms/card_grid_organism.dart';
import 'package:doormer/src/features/collection/presentation/organisms/card_reveal_organism.dart';
import 'package:doormer/src/features/collection/presentation/organisms/deck_list_organism.dart';
import 'package:doormer/src/features/collection/presentation/organisms/empty_deck_organism.dart';
import 'package:doormer/src/features/collection/presentation/pages/collection_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

/// The journey, end to end, against the real DI container and the real bundled
/// asset content. Every other test in this feature mounts one widget with
/// hand-made data; this is the only one that proves the parts are connected.
///
/// The asset is read from disk once and served from memory, rather than through
/// `rootBundle`. That is not a shortcut around the data layer — the JSON, the
/// parsing, the repository, the bloc and the whole widget tree are all real.
/// It exists because `rootBundle`'s real file I/O completes on the first
/// `testWidgets` mount in a process and then never again inside the fake-async
/// zone, which would make every test after the first hang on the spinner.
class _MemoryBundle extends CachingAssetBundle {
  final String _json;

  _MemoryBundle(this._json);

  @override
  Future<ByteData> load(String key) async {
    if (key == CollectionLocalDataSourceImpl.mockAssetPath) {
      return ByteData.view(Uint8List.fromList(utf8.encode(_json)).buffer);
    }
    // Card art: widget tests render a broken-image placeholder rather than
    // throwing, so an empty payload is enough to exercise layout.
    return ByteData(0);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == CollectionLocalDataSourceImpl.mockAssetPath) return _json;
    return '';
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
  // settling is impossible until the collection has arrived. Pump the async
  // gap first, then settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late final String assetJson;

  setUpAll(() {
    assetJson = File('assets/mock/mock_collection.json').readAsStringSync();
  });

  setUp(() async {
    // A fresh container per test: the repository is a singleton *by design*
    // because it holds the session's state, so leaking it between tests would
    // carry one test's draws into the next. `reset` is async — not awaiting it
    // lets the wipe land after the re-registration.
    await GetIt.instance.reset();
    initCollectionModule();

    // Swap only the bundle. Everything above the bundle stays real.
    await GetIt.instance.unregister<CollectionLocalDataSource>();
    GetIt.instance.registerLazySingleton<CollectionLocalDataSource>(
      () => CollectionLocalDataSourceImpl(bundle: _MemoryBundle(assetJson)),
    );
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
    await tester.tap(find.widgetWithText(DeckRowMolecule, 'Meridian'));
    await tester.pumpAndSettle();

    expect(find.byType(CardGridOrganism), findsOneWidget);
    // The asset holds 4 of Meridian's 6 cards.
    expect(find.byType(CardTileMolecule), findsNWidgets(4));
    expect(find.textContaining('Draw a card'), findsOneWidget);
  });

  testWidgets('a deck holding nothing shows the empty state, never a bare grid',
      (tester) async {
    await _pumpPhone(tester);
    await tester.tap(find.widgetWithText(DeckRowMolecule, 'Cinder'));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyDeckOrganism), findsOneWidget);
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('6 cards to find'), findsOneWidget);
    expect(find.byType(CardTileMolecule), findsNothing);
  });

  testWidgets('drawing reveals a card, and dismissing returns to the deck',
      (tester) async {
    await _pumpPhone(tester);
    await tester.tap(find.widgetWithText(DeckRowMolecule, 'Meridian'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Draw a card'));
    await tester.pumpAndSettle();

    expect(find.byType(CardRevealOrganism), findsOneWidget);
    // The asset's first Meridian step is Quadrant, a card not yet held.
    expect(find.text('A new one'), findsOneWidget);

    await tester.tap(find.byType(CardRevealOrganism));
    await tester.pumpAndSettle();

    expect(find.byType(CardRevealOrganism), findsNothing,
        reason: 'a reveal must not be able to stick on screen');
    // The drawn card has joined the grid.
    expect(find.byType(CardTileMolecule), findsNWidgets(5));
  });

  testWidgets('tapping a card opens its detail, and it can be closed',
      (tester) async {
    await _pumpPhone(tester);
    await tester.tap(find.widgetWithText(DeckRowMolecule, 'Meridian'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CardTileMolecule).first);
    await tester.pumpAndSettle();

    expect(find.byType(CardDetailOrganism), findsOneWidget);

    await tester.tap(find.byKey(const Key('card-detail-close')));
    await tester.pumpAndSettle();

    expect(find.byType(CardDetailOrganism), findsNothing,
        reason: 'the detail must not be a dead end');
  });

  testWidgets('going back from a deck returns to the list', (tester) async {
    await _pumpPhone(tester);
    await tester.tap(find.widgetWithText(DeckRowMolecule, 'Meridian'));
    await tester.pumpAndSettle();
    expect(find.byType(CardGridOrganism), findsOneWidget);

    await tester.tap(find.text('Decks'));
    await tester.pumpAndSettle();

    expect(find.byType(DeckListOrganism), findsOneWidget);
    expect(find.byType(CardGridOrganism), findsNothing);
  });
}
