import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/core/utils/invite_code_storage/in_memory_invite_code_storage.dart';
import 'package:doormer/src/features/profile/domain/entity/friend_profile.dart';
import 'package:doormer/src/features/profile/domain/usecase/find_student_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/forget_invite_code_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/load_friend_profile_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/reset_friend_code_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/send_friend_request_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/unblock_student_usecase.dart';
import 'package:doormer/src/features/profile/presentation/bloc/add_friend_bloc.dart';
import 'package:doormer/src/features/profile/presentation/pages/add_friend_page.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../fake_friends_repository.dart';

final _appAddress = Uri.parse('https://app.doormer.test/profile/add');

/// A student who hasn't set up friends yet.
const _noProfile = FriendProfile(
  hasProfile: false,
  nickname: '',
  friendCode: '',
  friendsTurnedOff: false,
  waitingRequests: 0,
);

void main() {
  setUpAll(AppLogger.disable);

  late FakeFriendsRepository repository;
  late InMemoryInviteCodeStorage inviteCodes;

  setUp(() {
    repository = FakeFriendsRepository();
    inviteCodes = InMemoryInviteCodeStorage();
    serviceLocator.registerFactory<AddFriendBloc>(
      () => AddFriendBloc(
        loadProfile: LoadFriendProfileUseCase(repository),
        findStudent: FindStudentUseCase(repository),
        sendRequest: SendFriendRequestUseCase(repository),
        unblockStudent: UnblockStudentUseCase(repository),
        resetCode: ResetFriendCodeUseCase(repository),
        forgetInviteCode: ForgetInviteCodeUseCase(inviteCodes),
      ),
    );
  });

  tearDown(() => serviceLocator.reset());

  Future<GoRouter> pumpAddFriend(
    WidgetTester tester, {
    String location = '/profile/add',
  }) async {
    tester.view.physicalSize = const Size(360, 1000);
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
              path: 'add',
              builder: (_, __) => AddFriendPage(appAddress: _appAddress),
            ),
            GoRoute(
              path: 'add/:code',
              builder: (_, state) => AddFriendPage(
                inviteCode: state.pathParameters['code'],
                appAddress: _appAddress,
              ),
            ),
            GoRoute(
              path: 'setup',
              builder: (_, state) => Scaffold(
                body: Text('setup, then ${state.uri.queryParameters['code']}'),
              ),
            ),
            GoRoute(
              path: 'friends/:friendId/cards',
              builder: (_, state) => Scaffold(
                body: Text('cards of ${state.pathParameters['friendId']}, '
                    '${(state.extra as FriendSummary?)?.nickname}'),
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

  /// What the page puts on the clipboard.
  List<String> watchClipboard(WidgetTester tester) {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    return copied;
  }

  Future<void> findCode(WidgetTester tester, String code) async {
    await tester.enterText(find.byKey(const Key('friend_code_field')), code);
    await tester.tap(find.text('Find'));
    await tester.pumpAndSettle();
  }

  /// Lets a toast run its course.
  Future<void> waitOutToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets('shows your code with a dash, and a box to find a friend',
      (tester) async {
    await pumpAddFriend(tester);

    expect(find.text('Add a friend'), findsOneWidget);
    expect(find.text('K7QM-2XPA'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Copy invite link'), findsOneWidget);
    expect(find.text('Reset code'), findsOneWidget);
    expect(find.text('Find'), findsOneWidget);
  });

  testWidgets('Copy puts your code on the clipboard, with its dash',
      (tester) async {
    final copied = watchClipboard(tester);
    await pumpAddFriend(tester);

    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();

    expect(copied, ['K7QM-2XPA']);
    expect(find.text('Code copied.'), findsOneWidget);
    await waitOutToast(tester);
  });

  testWidgets("Copy invite link copies the app's address, /add/ and your code",
      (tester) async {
    final copied = watchClipboard(tester);
    await pumpAddFriend(tester);

    await tester.tap(find.text('Copy invite link'));
    await tester.pumpAndSettle();

    expect(copied, ['https://app.doormer.test/add/K7QM2XPA']);
    expect(find.text('Invite link copied.'), findsOneWidget);
    await waitOutToast(tester);
  });

  testWidgets('finding a new code offers Send request, then says Request sent',
      (tester) async {
    await pumpAddFriend(tester);

    await findCode(tester, 'news-2345');
    expect(find.text('Nia'), findsOneWidget);
    await tester.tap(find.text('Send request'));
    await tester.pumpAndSettle();

    expect(find.text('Request sent'), findsOneWidget);
    expect(find.text('Send request'), findsNothing);
    expect(repository.calls, contains('sendRequest $niaCode code'));
  });

  testWidgets('a request that fails says why', (tester) async {
    repository.failNext['sendRequest'] =
        RefusedFailure(409, 'You have 100 friends. Remove one to add another.');
    await pumpAddFriend(tester);

    await findCode(tester, niaCode);
    await tester.tap(find.text('Send request'));
    await tester.pumpAndSettle();

    expect(find.text('You have 100 friends. Remove one to add another.'),
        findsOneWidget);
    expect(find.text('Send request'), findsOneWidget);
    await waitOutToast(tester);
  });

  testWidgets(
      "a student who sent you a request offers Accept, which makes you "
      "friends, and View cards opens theirs", (tester) async {
    await pumpAddFriend(tester);

    await findCode(tester, ruaCode);
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(find.text("You're friends"), findsOneWidget);
    await tester.tap(find.text('View cards'));
    await tester.pumpAndSettle();

    expect(find.text('cards of 55, Rua'), findsOneWidget);
  });

  testWidgets('a blocked student offers Unblock', (tester) async {
    await pumpAddFriend(tester);

    await findCode(tester, tamaCode);
    expect(find.text('You blocked them'), findsOneWidget);
    await tester.tap(find.text('Unblock'));
    await tester.pumpAndSettle();

    expect(find.text('Send request'), findsOneWidget);
  });

  testWidgets('your own code says so', (tester) async {
    await pumpAddFriend(tester);

    await findCode(tester, kaiCode);

    expect(find.text("That's your code."), findsOneWidget);
  });

  testWidgets('a code nobody has says so', (tester) async {
    await pumpAddFriend(tester);

    await findCode(tester, 'ZZZZ-2222');

    expect(find.text("We couldn't find that code. Check it and try again."),
        findsOneWidget);
  });

  testWidgets('Reset code warns first, then shows the new code',
      (tester) async {
    await pumpAddFriend(tester);

    await tester.tap(find.text('Reset code'));
    await tester.pumpAndSettle();
    expect(find.text('Your old code and invite links will stop working.'),
        findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.calls, isNot(contains('resetCode')));

    await tester.tap(find.text('Reset code'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Reset code').last);
    await tester.pumpAndSettle();

    expect(find.text('ZQ9X-4W2T'), findsOneWidget);
  });

  testWidgets(
      'opened from an invite link, checks its code at once and forgets it',
      (tester) async {
    await inviteCodes.keep(ruaCode);

    await pumpAddFriend(tester, location: '/profile/add/$ruaCode');

    expect(find.text('Rua'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('RUAR-5555'), findsOneWidget, reason: 'in the box');
    expect(await inviteCodes.read(), isNull);

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(repository.calls, contains('sendRequest $ruaCode link'));
  });

  testWidgets('opened from an invite link before setup, sets up first',
      (tester) async {
    repository.profile = _noProfile;

    final router =
        await pumpAddFriend(tester, location: '/profile/add/$ruaCode');

    expect(find.text('setup, then $ruaCode'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.toString(),
        '/profile/setup?code=$ruaCode');
  });

  testWidgets('opened from an invite link before setup, forgets the kept code',
      (tester) async {
    await inviteCodes.keep(ruaCode);
    repository.profile = _noProfile;

    await pumpAddFriend(tester, location: '/profile/add/$ruaCode');

    expect(find.text('setup, then $ruaCode'), findsOneWidget);
    expect(await inviteCodes.read(), isNull,
        reason: 'setup carries the code in its address instead');
  });

  testWidgets('the back arrow goes to Profile', (tester) async {
    await pumpAddFriend(tester);

    await tester.tap(find.byKey(const Key('page_back')));
    await tester.pumpAndSettle();

    expect(find.text('Profile page'), findsOneWidget);
  });
}
