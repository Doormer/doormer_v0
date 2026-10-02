import 'dart:async';

import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/routes/destination_routes.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/collection/domain/entity/deck_progress.dart';
import 'package:doormer/src/features/collection/domain/repository/collection_repository.dart';
import 'package:doormer/src/features/collection/domain/usecase/draw_card_usecase.dart';
import 'package:doormer/src/features/collection/domain/usecase/load_collection_usecase.dart';
import 'package:doormer/src/features/collection/domain/usecase/load_decks_usecase.dart';
import 'package:doormer/src/features/collection/domain/usecase/shatter_copy_usecase.dart';
import 'package:doormer/src/features/collection/presentation/bloc/collection_bloc.dart';
import 'package:doormer/src/features/collection/presentation/pages/collection_page.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/submit_photo_question_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/pages/ask_by_photo_page.dart';
import 'package:doormer/src/shared/design/atomic/organisms/navigation_bar_organism.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Never asked anything: the Solve page only opens here.
class _UnusedQuestionsRepository implements QuestionsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Never answers, so the collection stays on its loading screen - the screen
/// a switch to Cards lands on first.
class _PendingCollectionRepository implements CollectionRepository {
  @override
  Future<({int quarkBalance, List<DeckProgress> decks})> loadDecks() =>
      Completer<({int quarkBalance, List<DeckProgress> decks})>().future;

  // Nothing has been read, so nothing is remembered.
  @override
  ({int quarkBalance, List<DeckProgress> decks})? get lastDeckList => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  setUpAll(AppLogger.disable);

  setUp(() {
    serviceLocator.registerFactory<AskByPhotoBloc>(
      () => AskByPhotoBloc(
        submitPhotoQuestionUseCase:
            SubmitPhotoQuestionUseCase(_UnusedQuestionsRepository()),
      ),
    );
    final collection = _PendingCollectionRepository();
    serviceLocator.registerFactory<CollectionBloc>(
      () => CollectionBloc(
        loadDecks: LoadDecksUseCase(collection),
        loadCollection: LoadCollectionUseCase(collection),
        drawCard: DrawCardUseCase(collection),
        shatterCopy: ShatterCopyUseCase(collection),
      ),
    );
  });

  tearDown(() async {
    await serviceLocator.reset();
  });

  // Solve and Cards are tabs of one bar. A page transition between them slid
  // the whole page in, bar and all, so two bars crossed mid-switch.
  testWidgets('Solve and Cards swap in place, and the bar stands still',
      (tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/questions/photo',
      routes: destinationRoutes,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    final bar = tester.getRect(find.byType(NavigationBarOrganism));

    await tester.tap(find.byIcon(Icons.style_outlined));
    await tester.pump();

    expect(find.byType(AskByPhotoPage), findsNothing);
    expect(find.byType(CollectionPage), findsOneWidget);
    expect(tester.getRect(find.byType(NavigationBarOrganism)), bar);

    await tester.tap(find.byIcon(Icons.document_scanner_outlined));
    await tester.pump();

    expect(find.byType(CollectionPage), findsNothing);
    expect(find.byType(AskByPhotoPage), findsOneWidget);
    expect(tester.getRect(find.byType(NavigationBarOrganism)), bar);
  });
}
