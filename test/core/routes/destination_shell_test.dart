import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/routes/destination_shell.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/shared/design/atomic/atoms/toast_atom.dart';
import 'package:doormer/src/shared/friends/bloc/waiting_friend_requests_bloc.dart';
import 'package:doormer/src/shared/levels/bloc/level_progress_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../features/levels/fake_levels_repository.dart';
import '../../features/levels/register_levels.dart';

const _newMoon = "New moon! You're level 4.";

/// Tells the app the browser tab is now [state], as the engine does. The
/// binding fills in the states between, so hidden to resumed passes through
/// inactive, which is when `AppLifecycleListener.onShow` fires. Calling
/// `handleAppLifecycleStateChanged` directly fills nothing in.
Future<void> _tabBecomes(WidgetTester tester, AppLifecycleState state) =>
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.lifecycle.name,
      SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
      (_) {},
    );

/// The student leaves the tab, then comes back to it.
Future<void> _leaveTabAndReturn(WidgetTester tester) async {
  await _tabBecomes(tester, AppLifecycleState.hidden);
  await _tabBecomes(tester, AppLifecycleState.resumed);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(AppLogger.disable);

  setUp(() {
    // The shell reads Profile's dot from it.
    serviceLocator.registerLazySingleton(WaitingFriendRequestsBloc.new);
  });

  tearDown(() => serviceLocator.reset());

  /// The nav bar shell on Solve, with stand-ins for its pages.
  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/questions/photo',
      routes: [
        DestinationShell.route(
          branches: [
            for (final (path, name) in const [
              ('/saved', 'Saved page'),
              ('/questions/photo', 'Solve page'),
              ('/collection', 'Cards page'),
              ('/profile', 'Profile page'),
            ])
              StatefulShellBranch(routes: [
                GoRoute(
                  path: path,
                  builder: (_, __) => Scaffold(body: Text(name)),
                ),
              ]),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  /// Lets the toast run its course.
  Future<void> waitOutToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets('counts the day when it first shows, and keeps the progress',
      (tester) async {
    final levels = registerLevels(FakeLevelsRepository([alreadyCountedAt32]));

    await pumpShell(tester);

    expect(levels.counts, 1);
    expect(
      serviceLocator<LevelProgressBloc>().state.progress,
      alreadyCountedAt32.progress,
    );
  });

  testWidgets('counts again when the browser tab comes back into view',
      (tester) async {
    final levels = registerLevels(
        FakeLevelsRepository([alreadyCountedAt32, alreadyCountedAt32]));
    await pumpShell(tester);

    await _leaveTabAndReturn(tester);

    expect(levels.counts, 2);
  });

  testWidgets('does not count when the window only gets focus back',
      (tester) async {
    final levels = registerLevels(
        FakeLevelsRepository([alreadyCountedAt32, alreadyCountedAt32]));
    await pumpShell(tester);

    await _tabBecomes(tester, AppLifecycleState.resumed);
    await _tabBecomes(tester, AppLifecycleState.inactive);
    await _tabBecomes(tester, AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(levels.counts, 1);
  });

  testWidgets(
      'a new level shows its toast at the top for 4 seconds, and only once',
      (tester) async {
    final levels =
        registerLevels(FakeLevelsRepository([newMoonAt32, alreadyCountedAt32]));

    await pumpShell(tester);

    final toast = find.widgetWithText(ToastAtom, _newMoon);
    expect(toast, findsOneWidget);
    expect(tester.widget<ToastAtom>(toast).kind, ToastKind.success);
    expect(tester.getCenter(toast).dy, lessThan(690 / 2));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text(_newMoon), findsOneWidget, reason: 'still there at 3 s');
    await waitOutToast(tester);
    expect(find.text(_newMoon), findsNothing);

    // The same day, counted again when the tab comes back, then another
    // page, which rebuilds the shell but counts nothing: nothing new to
    // celebrate.
    await _leaveTabAndReturn(tester);
    await tester.tap(find.byIcon(Icons.style_outlined));
    await tester.pumpAndSettle();

    expect(levels.counts, 2);
    expect(find.text(_newMoon), findsNothing);
  });

  testWidgets(
      'a count that fails shows nothing, and the next tab return tries again',
      (tester) async {
    final levels = registerLevels(FakeLevelsRepository([newMoonAt32]))
      ..failNext = ServerFailure("We couldn't count today as an active day.");

    await pumpShell(tester);

    expect(levels.counts, 1);
    expect(find.byType(ToastAtom), findsNothing);
    expect(serviceLocator<LevelProgressBloc>().state.progress, isNull);

    await _leaveTabAndReturn(tester);

    expect(levels.counts, 2);
    expect(find.text(_newMoon), findsOneWidget);
    await waitOutToast(tester);
  });
}
