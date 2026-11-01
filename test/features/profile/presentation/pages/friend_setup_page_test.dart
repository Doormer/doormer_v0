import 'dart:async';

import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/profile/domain/entity/friend_profile.dart';
import 'package:doormer/src/features/profile/domain/usecase/load_friend_profile_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/load_picture_choices_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/save_friend_profile_usecase.dart';
import 'package:doormer/src/features/profile/presentation/bloc/friend_setup_bloc.dart';
import 'package:doormer/src/features/profile/presentation/molecules/nickname_field_molecule.dart';
import 'package:doormer/src/features/profile/presentation/organisms/picture_picker_organism.dart';
import 'package:doormer/src/features/profile/presentation/pages/friend_setup_page.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../fake_friends_repository.dart';

void main() {
  setUpAll(AppLogger.disable);

  late FakeFriendsRepository repository;

  setUp(() {
    repository = FakeFriendsRepository()
      ..profile = const FriendProfile(
        hasProfile: false,
        nickname: '',
        friendCode: '',
        friendsTurnedOff: false,
        waitingRequests: 0,
      );
    serviceLocator.registerFactory<FriendSetupBloc>(
      () => FriendSetupBloc(
        loadProfile: LoadFriendProfileUseCase(repository),
        loadPictureChoices: LoadPictureChoicesUseCase(repository),
        saveProfile: SaveFriendProfileUseCase(repository),
      ),
    );
  });

  tearDown(() => serviceLocator.reset());

  /// Opens setup at [location]. With [settle] false it shows the first frame
  /// only, so a load the repository holds can be seen.
  Future<GoRouter> pumpSetup(
    WidgetTester tester, {
    String location = '/profile/setup',
    bool settle = true,
    Size window = const Size(360, 1200),
  }) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/profile',
          builder: (_, __) => const Scaffold(body: Text('Profile page')),
          routes: [
            GoRoute(
              path: 'setup',
              builder: (_, state) => FriendSetupPage(
                inviteCode: state.uri.queryParameters['code'],
              ),
            ),
            GoRoute(
              path: 'add/:code',
              builder: (_, state) => Scaffold(
                body: Text('check ${state.pathParameters['code']}'),
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
    if (settle) await tester.pumpAndSettle();
    return router;
  }

  testWidgets(
      'asks for a nickname and a picture, and says above Done what friends '
      'will see', (tester) async {
    await pumpSetup(tester);

    expect(find.text('Set up friends'), findsOneWidget);
    expect(find.text("Don't use your full name."), findsOneWidget);
    expect(find.text('Picture'), findsOneWidget);
    expect(
      find.text('Friends you accept will see your nickname, picture, level '
          'and cards.'),
      findsOneWidget,
    );
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets(
      'on a wide screen, keeps the nickname box, the pictures and Done to '
      '520 wide, on the left', (tester) async {
    await pumpSetup(tester, window: const Size(760, 1200));

    final parts = [
      find.byType(NicknameFieldMolecule),
      find.byType(PicturePickerOrganism),
      find.widgetWithText(AppButtonAtom, 'Done'),
    ];
    final left = tester.getRect(parts.first).left;
    for (final part in parts) {
      final rect = tester.getRect(part);
      expect(rect.width, lessThanOrEqualTo(520), reason: '$part');
      expect(rect.left, left, reason: '$part');
    }
    expect(left, lessThan((760 - 520) / 2), reason: 'not centred');
  });

  testWidgets('Done saves the nickname and the card picked, then goes back',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final router = await pumpSetup(tester);

    await tester.enterText(find.byKey(const Key('nickname_field')), 'Rangi');
    await tester.tap(find.bySemanticsLabel('Gnomon'));
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(repository.calls, contains('saveProfile Rangi gnomon'));
    expect(router.routerDelegate.currentConfiguration.uri.path, '/profile');
    semantics.dispose();
  });

  testWidgets(
      'Enter in the nickname box sends nothing: only Done, under what friends '
      'will see, saves', (tester) async {
    final router = await pumpSetup(tester);

    await tester.enterText(find.byKey(const Key('nickname_field')), 'Rangi');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(repository.calls, isNot(contains(startsWith('saveProfile'))));
    expect(
        router.routerDelegate.currentConfiguration.uri.path, '/profile/setup');

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(repository.calls, contains('saveProfile Rangi null'));
  });

  testWidgets('a nickname that breaks a rule says which, under the box',
      (tester) async {
    await pumpSetup(tester);

    await tester.enterText(find.byKey(const Key('nickname_field')), '12345');
    await tester.tap(find.text('Done'));
    await tester.pump();

    expect(find.text('Include at least one letter.'), findsOneWidget);
    expect(repository.calls, isNot(contains(startsWith('saveProfile'))));
  });

  testWidgets('with no cards yet, says so, and setup can carry on',
      (tester) async {
    repository.pictureChoices = [];
    final router = await pumpSetup(tester);

    expect(find.textContaining('Draw one on Cards.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('nickname_field')), 'Rangi');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(repository.calls, contains('saveProfile Rangi null'));
    expect(router.routerDelegate.currentConfiguration.uri.path, '/profile');
  });

  testWidgets('Edit starts from the saved nickname', (tester) async {
    repository.profile = kaiProfile;

    await pumpSetup(tester);

    expect(find.text('Edit nickname and picture'), findsOneWidget);
    expect(find.text('Kai'), findsOneWidget);
  });

  testWidgets(
      'says neither heading until it knows whether the student is set up',
      (tester) async {
    repository
      ..profile = kaiProfile
      ..hold = Completer<void>()
      ..failNext['loadProfile'] =
          NetworkFailure("We couldn't load your friends.");

    await pumpSetup(tester, settle: false);

    expect(find.byKey(const Key('page_back')), findsOneWidget);
    expect(find.text('Set up friends'), findsNothing);
    expect(find.text('Edit nickname and picture'), findsNothing);

    repository.hold!.complete();
    await tester.pumpAndSettle();

    expect(find.text("We couldn't load your friends."), findsOneWidget);
    expect(find.text('Set up friends'), findsNothing);
    expect(find.text('Edit nickname and picture'), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Edit nickname and picture'), findsOneWidget);
  });

  testWidgets('in Edit, cards that fail to load keep the Edit heading',
      (tester) async {
    repository
      ..profile = kaiProfile
      ..failNext['loadPictureChoices'] =
          NetworkFailure("We couldn't load your cards.");

    await pumpSetup(tester);

    expect(find.text("We couldn't load your cards."), findsOneWidget);
    expect(find.text('Edit nickname and picture'), findsOneWidget);
  });

  testWidgets(
      'in Edit, the heading and the form stay, with Done spinning, while the '
      'page closes', (tester) async {
    repository.profile = kaiProfile;
    final router = await pumpSetup(tester);

    await tester.tap(find.text('Done'));
    await tester.pump();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/profile');
    expect(find.text('Edit nickname and picture'), findsOneWidget);
    expect(find.byKey(const Key('nickname_field')), findsOneWidget);
    expect(
      tester.widget<AppButtonAtom>(find.byType(AppButtonAtom)).isLoading,
      isTrue,
    );
  });

  testWidgets('from an invite link, Done opens the check', (tester) async {
    final router =
        await pumpSetup(tester, location: '/profile/setup?code=$ruaCode');

    await tester.enterText(find.byKey(const Key('nickname_field')), 'Rangi');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('check $ruaCode'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path,
        '/profile/add/$ruaCode');
  });

  testWidgets('the back arrow leaves setup for Profile', (tester) async {
    await pumpSetup(tester);

    await tester.tap(find.byKey(const Key('page_back')));
    await tester.pumpAndSettle();

    expect(find.text('Profile page'), findsOneWidget);
    expect(repository.calls, isNot(contains(startsWith('saveProfile'))));
  });
}
