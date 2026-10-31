import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/profile/domain/entity/friend_profile.dart';
import 'package:doormer/src/features/profile/domain/usecase/load_friend_profile_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/load_picture_choices_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/save_friend_profile_usecase.dart';
import 'package:doormer/src/features/profile/presentation/bloc/friend_setup_bloc.dart';
import 'package:doormer/src/features/profile/presentation/pages/friend_setup_page.dart';
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

  Future<GoRouter> pumpSetup(
    WidgetTester tester, {
    String location = '/profile/setup',
  }) async {
    tester.view.physicalSize = const Size(360, 1200);
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
    await tester.pumpAndSettle();
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
      find.text('Friends you accept will see your nickname, picture and '
          'cards.'),
      findsOneWidget,
    );
    expect(find.text('Done'), findsOneWidget);
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
