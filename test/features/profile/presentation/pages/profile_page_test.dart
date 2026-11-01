import 'dart:async';

import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/profile/domain/entity/friend_profile.dart';
import 'package:doormer/src/features/profile/domain/entity/friend_request.dart';
import 'package:doormer/src/features/profile/domain/usecase/accept_friend_request_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/block_student_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/decline_friend_request_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/load_friend_profile_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/load_friend_requests_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/load_friends_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/remove_friend_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/report_student_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/sign_out_usecase.dart';
import 'package:doormer/src/features/profile/presentation/bloc/friends_bloc.dart';
import 'package:doormer/src/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:doormer/src/features/profile/presentation/molecules/friend_request_row_molecule.dart';
import 'package:doormer/src/features/profile/presentation/molecules/friend_row_molecule.dart';
import 'package:doormer/src/features/profile/presentation/organisms/level_strip_organism.dart';
import 'package:doormer/src/features/profile/presentation/pages/profile_page.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/molecules/confirm_dialog_molecule.dart';
import 'package:doormer/src/shared/friends/bloc/waiting_friend_requests_bloc.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/levels/bloc/level_progress_bloc.dart';
import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:doormer/src/shared/levels/entity/level_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../levels/register_levels.dart';
import '../../fake_friends_repository.dart';

/// 540 active days: level 21, 32 days from a star.
const _at540 = LevelProgress(
  activeDays: 540,
  level: Level(number: 21, suns: 1, moons: 1, stars: 1),
  activeDaysToNextLevel: 32,
  nextLevelIcon: LevelIcon.star,
);

/// The first active day of a student who just signed up.
const _at1 = LevelProgress(
  activeDays: 1,
  level: Level(number: 0, suns: 0, moons: 0, stars: 0),
  activeDaysToNextLevel: 4,
  nextLevelIcon: LevelIcon.star,
);

class _FakeSessionService implements SessionService {
  int logouts = 0;

  @override
  Future<void> logout() async {
    logouts++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(AppLogger.disable);

  late FakeFriendsRepository friends;
  late _FakeSessionService session;
  late WaitingFriendRequestsBloc waiting;

  setUp(() {
    friends = FakeFriendsRepository();
    session = _FakeSessionService();
    waiting = WaitingFriendRequestsBloc();
    // Profile reads the student's level from the app-wide bloc.
    registerLevels();
    serviceLocator.registerFactory<ProfileBloc>(
      () => ProfileBloc(signOut: SignOutUseCase(session)),
    );
    serviceLocator.registerFactory<FriendsBloc>(
      () => FriendsBloc(
        loadProfile: LoadFriendProfileUseCase(friends),
        loadRequests: LoadFriendRequestsUseCase(friends),
        loadFriends: LoadFriendsUseCase(friends),
        acceptRequest: AcceptFriendRequestUseCase(friends),
        declineRequest: DeclineFriendRequestUseCase(friends),
        removeFriend: RemoveFriendUseCase(friends),
        blockStudent: BlockStudentUseCase(friends),
        reportStudent: ReportStudentUseCase(friends),
        waitingRequests: waiting,
      ),
    );
  });

  tearDown(() async {
    await serviceLocator.reset();
  });

  /// Profile, with stand-ins for the pages it opens.
  Future<GoRouter> pumpProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (_, state) =>
              ProfilePage(isCovered: state.uri.path != '/profile'),
          routes: [
            for (final page in ['setup', 'add', 'blocked'])
              GoRoute(
                path: page,
                builder: (_, __) => Scaffold(body: Text('$page page')),
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
        GoRoute(
          path: '/auth/login',
          builder: (_, __) => const Text('login'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp.router(
          theme: AppTheme.dark,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> chooseFromMenu(
    WidgetTester tester, {
    required Finder row,
    required String action,
  }) async {
    await tester
        .tap(find.descendant(of: row, matching: find.byIcon(Icons.more_vert)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(action));
    await tester.pumpAndSettle();
  }

  Finder friendRow(String nickname) =>
      find.widgetWithText(FriendRowMolecule, nickname);
  Finder requestRow(String nickname) =>
      find.widgetWithText(FriendRequestRowMolecule, nickname);

  const removeMessage =
      "You'll stop seeing each other's cards. You can add each other again "
      'later.';
  const blockMessage = "They won't see your cards, and their requests won't "
      "reach you. They won't be told.";

  /// The dialog that asks before Remove or Block.
  final dialog = find.byType(ConfirmDialogMolecule);

  /// Expects the dialog to ask [title] and say [message], with Cancel and
  /// [confirmLabel].
  void expectAsked({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    expect(dialog, findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.text(title)),
        findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.text(message)),
        findsOneWidget);
    for (final label in ['Cancel', confirmLabel]) {
      expect(
        find.descendant(
          of: dialog,
          matching: find.widgetWithText(AppButtonAtom, label),
        ),
        findsOneWidget,
      );
    }
  }

  /// Taps the dialog's button saying [label].
  Future<void> answer(WidgetTester tester, String label) async {
    await tester.tap(find.descendant(
      of: dialog,
      matching: find.widgetWithText(AppButtonAtom, label),
    ));
    await tester.pumpAndSettle();
  }

  /// Lets an error toast run its course.
  Future<void> waitOutToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'shows the student, Add a friend, the requests and the friends, then '
      'Blocked and Sign out', (tester) async {
    await pumpProfile(tester);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Kai'), findsOneWidget);
    expect(find.text('K7QM-2XPA'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Add a friend'), findsOneWidget);
    expect(find.text('Requests'), findsOneWidget);
    expect(requestRow('Rua'), findsOneWidget);
    expect(find.text('Friends'), findsOneWidget);
    expect(friendRow('Alex'), findsOneWidget);
    expect(friendRow('Sam'), findsOneWidget);
    expect(find.text('Blocked'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Requests')).dy,
      lessThan(tester.getTopLeft(find.text('Friends')).dy),
    );
    expect(waiting.state.count, 1, reason: 'the dot on the nav bar');
  });

  testWidgets('with no request waiting, there is no Requests section',
      (tester) async {
    friends.requests = [];
    // The dot still shows 3 from an earlier count.
    waiting.add(const WaitingFriendRequestsCounted(3));
    await tester.pump();
    expect(waiting.state.count, 3);

    await pumpProfile(tester);

    expect(find.text('Requests'), findsNothing);
    expect(waiting.state.count, 0);
  });

  testWidgets('with no friends yet, says how to add one', (tester) async {
    friends.friends = [];

    await pumpProfile(tester);

    expect(find.text('No friends yet. Add one with their friend code.'),
        findsOneWidget);
  });

  testWidgets(
      'before setup, says what friends is, with only Set up friends and '
      'Sign out', (tester) async {
    friends.profile = const FriendProfile(
      hasProfile: false,
      nickname: '',
      friendCode: '',
      friendsTurnedOff: false,
      waitingRequests: 0,
    );

    await pumpProfile(tester);

    expect(
        find.text("Add friends with a friend code and see each other's cards."),
        findsOneWidget);
    expect(find.text('Set up friends'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Add a friend'), findsNothing);
    expect(find.text('Friends'), findsNothing);

    await tester.tap(find.text('Set up friends'));
    await tester.pumpAndSettle();

    expect(find.text('setup page'), findsOneWidget);
  });

  testWidgets('with friends turned off, says so, and Sign out still works',
      (tester) async {
    friends.profile = const FriendProfile(
      hasProfile: true,
      nickname: 'Kai',
      friendCode: kaiCode,
      friendsTurnedOff: true,
      waitingRequests: 0,
    );

    await pumpProfile(tester);

    expect(
        find.text('Friends is turned off for your account.'), findsOneWidget);
    expect(find.text('Add a friend'), findsNothing);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(session.logouts, 1);
  });

  testWidgets(
      "when friends can't load, says so with Try again, and Sign out stays",
      (tester) async {
    friends.failNext['loadFriends'] =
        NetworkFailure("We couldn't load your friends.");

    await pumpProfile(tester);

    expect(find.text("We couldn't load your friends."), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(friendRow('Sam'), findsOneWidget);
  });

  testWidgets('Accept makes the sender a friend, and the dot goes',
      (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(find.text('Requests'), findsNothing);
    expect(friendRow('Rua'), findsOneWidget);
    expect(waiting.state.count, 0);
  });

  testWidgets('Decline takes the request away', (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();

    expect(find.text('Rua'), findsNothing);
    expect(friends.calls, contains('declineRequest 9'));
  });

  testWidgets("a friend's row opens their collection", (tester) async {
    final router = await pumpProfile(tester);

    await tester.tap(find.text('Sam'));
    await tester.pumpAndSettle();

    expect(find.text('cards of 42, Sam'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path,
        '/profile/friends/42/cards');
  });

  testWidgets('Remove asks first, and confirming takes the friend away',
      (tester) async {
    await pumpProfile(tester);

    await chooseFromMenu(tester, row: friendRow('Sam'), action: 'Remove');
    expectAsked(
      title: 'Remove Sam?',
      message: removeMessage,
      confirmLabel: 'Remove',
    );
    expect(friends.calls, isNot(contains('removeFriend 42')),
        reason: 'nothing happens until the student confirms');
    await answer(tester, 'Remove');

    expect(dialog, findsNothing);
    expect(find.text('Sam'), findsNothing);
    expect(friends.calls, contains('removeFriend 42'));
  });

  testWidgets('Cancel on Remove keeps the friend', (tester) async {
    await pumpProfile(tester);

    await chooseFromMenu(tester, row: friendRow('Sam'), action: 'Remove');
    await answer(tester, 'Cancel');

    expect(dialog, findsNothing);
    expect(friendRow('Sam'), findsOneWidget);
    expect(friends.calls, isNot(contains('removeFriend 42')));
  });

  testWidgets("Block on a friend's row asks first, then blocks them",
      (tester) async {
    await pumpProfile(tester);

    await chooseFromMenu(tester, row: friendRow('Sam'), action: 'Block');
    expectAsked(
      title: 'Block Sam?',
      message: blockMessage,
      confirmLabel: 'Block',
    );
    await answer(tester, 'Block');

    expect(find.text('Sam'), findsNothing);
    expect(friends.calls, contains('blockStudent 42'));
  });

  testWidgets('Cancel on Block keeps the friend, unblocked', (tester) async {
    await pumpProfile(tester);

    await chooseFromMenu(tester, row: friendRow('Sam'), action: 'Block');
    await answer(tester, 'Cancel');

    expect(friendRow('Sam'), findsOneWidget);
    expect(friends.calls, isNot(contains('blockStudent 42')));
  });

  testWidgets(
      "Block on a request asks first, then takes it away, and the sender "
      "isn't added", (tester) async {
    await pumpProfile(tester);

    await chooseFromMenu(tester, row: requestRow('Rua'), action: 'Block');
    expectAsked(
      title: 'Block Rua?',
      message: blockMessage,
      confirmLabel: 'Block',
    );
    await answer(tester, 'Block');

    expect(find.text('Rua'), findsNothing);
    expect(friends.calls, contains('blockStudent 55'));
  });

  testWidgets('Cancel on Block keeps the request waiting', (tester) async {
    await pumpProfile(tester);

    await chooseFromMenu(tester, row: requestRow('Rua'), action: 'Block');
    await answer(tester, 'Cancel');

    expect(requestRow('Rua'), findsOneWidget);
    expect(friends.calls, isNot(contains('blockStudent 55')));
  });

  testWidgets('Report opens the sheet, and sending says thanks',
      (tester) async {
    await pumpProfile(tester);

    await chooseFromMenu(tester, row: friendRow('Sam'), action: 'Report');
    expect(find.text('Report Sam'), findsOneWidget);
    await tester.tap(find.text('Rude or hurtful nickname'));
    await tester.pump();
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();

    expect(find.text('Thanks. The Doormer team will look at this.'),
        findsOneWidget);
    expect(friends.calls, contains('reportStudent 42 rudeNickname'));
    expect(friendRow('Sam'), findsOneWidget,
        reason: 'a report on its own removes no one');
  });

  testWidgets(
      'Block in the report sheet asks first, then closes the sheet and '
      'blocks the student', (tester) async {
    await pumpProfile(tester);

    await chooseFromMenu(tester, row: requestRow('Rua'), action: 'Report');
    await tester.tap(find.text('Block'));
    await tester.pumpAndSettle();
    expectAsked(
      title: 'Block Rua?',
      message: blockMessage,
      confirmLabel: 'Block',
    );
    expect(find.text('Report Rua'), findsOneWidget,
        reason: 'the sheet waits under the dialog');
    await answer(tester, 'Block');

    expect(find.text('Report Rua'), findsNothing);
    expect(find.text('Rua'), findsNothing);
    expect(friends.calls, contains('blockStudent 55'));
  });

  testWidgets('Cancel on Block leaves the report sheet open', (tester) async {
    await pumpProfile(tester);

    await chooseFromMenu(tester, row: requestRow('Rua'), action: 'Report');
    await tester.tap(find.text('Block'));
    await tester.pumpAndSettle();
    await answer(tester, 'Cancel');

    expect(dialog, findsNothing);
    expect(find.text('Report Rua'), findsOneWidget);
    expect(friends.calls, isNot(contains('blockStudent 55')));
  });

  testWidgets(
      "a report that lands while another student's sheet is open shows no "
      'thanks on it', (tester) async {
    await pumpProfile(tester);
    await chooseFromMenu(tester, row: friendRow('Sam'), action: 'Report');
    await tester.tap(find.text('Rude or hurtful nickname'));
    await tester.pump();
    friends.hold = Completer<void>();
    await tester.tap(find.text('Send report'));
    await tester.pump();

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await chooseFromMenu(tester, row: requestRow('Rua'), action: 'Report');
    friends.hold!.complete();
    await tester.pumpAndSettle();

    expect(friends.calls, contains('reportStudent 42 rudeNickname'));
    expect(find.text('Report Rua'), findsOneWidget);
    expect(
        find.text('Thanks. The Doormer team will look at this.'), findsNothing);
    expect(find.text('Send report'), findsOneWidget);
  });

  for (final (button, page) in [
    ('Edit', 'setup page'),
    ('Add a friend', 'add page'),
    ('Blocked', 'blocked page'),
  ]) {
    testWidgets('$button opens its page', (tester) async {
      await pumpProfile(tester);

      await tester.tap(find.text(button));
      await tester.pumpAndSettle();

      expect(find.text(page), findsOneWidget);
    });
  }

  testWidgets('an action that fails says why', (tester) async {
    friends.failNext['removeFriend'] =
        NetworkFailure("We couldn't remove that friend. Try again.");
    await pumpProfile(tester);

    await chooseFromMenu(tester, row: friendRow('Sam'), action: 'Remove');
    await answer(tester, 'Remove');

    expect(find.text("We couldn't remove that friend. Try again."),
        findsOneWidget);
    expect(friendRow('Sam'), findsOneWidget);
    await waitOutToast(tester);
  });

  testWidgets('coming back from a page under Profile reads friends again',
      (tester) async {
    final router = await pumpProfile(tester);

    router.go('/profile/add');
    await tester.pumpAndSettle();
    friends.requests = [
      ...friends.requests,
      FriendRequest(
        requestId: '10',
        from: nia,
        sentAt: DateTime.utc(2026, 10, 26, 10),
      ),
    ];
    router.go('/profile');
    await tester.pumpAndSettle();

    expect(requestRow('Nia'), findsOneWidget);
    expect(waiting.state.count, 2);
  });

  testWidgets('signs out and opens login', (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(session.logouts, 1);
    expect(find.text('login'), findsOneWidget);
  });

  testWidgets(
      "shows the student's level under their friend code once a count of "
      'the day brings it', (tester) async {
    await pumpProfile(tester);
    expect(find.byType(LevelStripOrganism), findsNothing,
        reason: 'no count of the day yet');

    serviceLocator<LevelProgressBloc>().add(const LevelProgressUpdated(_at540));
    await tester.pumpAndSettle();

    expect(find.text('Level 21'), findsOneWidget);
    expect(find.text('540 active days · 32 to your next star'), findsOneWidget);
    expect(tester.getRect(find.byType(LevelStripOrganism)).top,
        greaterThanOrEqualTo(tester.getRect(find.text('K7QM-2XPA')).bottom));
  });

  testWidgets('before setup, the level sits above the friends intro',
      (tester) async {
    friends.profile = const FriendProfile(
      hasProfile: false,
      nickname: '',
      friendCode: '',
      friendsTurnedOff: false,
      waitingRequests: 0,
    );
    serviceLocator<LevelProgressBloc>().add(const LevelProgressUpdated(_at1));

    await pumpProfile(tester);

    expect(find.text('Level 0'), findsOneWidget);
    expect(find.text('1 active day · 4 to your next star'), findsOneWidget);
    expect(
      tester.getRect(find.byType(LevelStripOrganism)).bottom,
      lessThanOrEqualTo(tester
          .getRect(find.text(
              "Add friends with a friend code and see each other's cards."))
          .top),
    );
  });

  testWidgets('ⓘ opens How levels work, and Got it closes it', (tester) async {
    serviceLocator<LevelProgressBloc>().add(const LevelProgressUpdated(_at540));
    await pumpProfile(tester);

    await tester.tap(find.byTooltip('How levels work'));
    await tester.pumpAndSettle();
    expect(find.text('Friends you add see your level.'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Friends you add see your level.'), findsNothing);
  });
}
