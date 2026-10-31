import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/profile/domain/usecase/load_blocked_students_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/unblock_student_usecase.dart';
import 'package:doormer/src/features/profile/presentation/bloc/blocked_students_bloc.dart';
import 'package:doormer/src/features/profile/presentation/pages/blocked_students_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../fake_friends_repository.dart';

void main() {
  setUpAll(AppLogger.disable);

  late FakeFriendsRepository repository;

  setUp(() {
    repository = FakeFriendsRepository();
    serviceLocator.registerFactory<BlockedStudentsBloc>(
      () => BlockedStudentsBloc(
        loadBlockedStudents: LoadBlockedStudentsUseCase(repository),
        unblockStudent: UnblockStudentUseCase(repository),
      ),
    );
  });

  tearDown(() => serviceLocator.reset());

  Future<GoRouter> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/profile/blocked',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (_, __) => const Scaffold(body: Text('Profile page')),
          routes: [
            GoRoute(
              path: 'blocked',
              builder: (_, __) => const BlockedStudentsPage(),
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

  testWidgets('lists the blocked students under its heading', (tester) async {
    await pumpPage(tester);

    expect(find.text('Blocked students'), findsOneWidget);
    expect(find.text('Tama'), findsOneWidget);
    expect(find.text('Unblock'), findsOneWidget);
  });

  testWidgets('Unblock takes the student off the list', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Unblock'));
    await tester.pumpAndSettle();

    expect(find.text('Tama'), findsNothing);
    expect(find.text("You haven't blocked anyone."), findsOneWidget);
    expect(repository.calls, contains('unblockStudent 66'));
  });

  testWidgets('says so when no one is blocked', (tester) async {
    repository.blocked = [];

    await pumpPage(tester);

    expect(find.text("You haven't blocked anyone."), findsOneWidget);
  });

  testWidgets('a list that fails to load can be tried again', (tester) async {
    repository.failNext['loadBlockedStudents'] =
        NetworkFailure("We couldn't load the students you've blocked.");

    await pumpPage(tester);
    expect(find.text("We couldn't load the students you've blocked."),
        findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Tama'), findsOneWidget);
  });

  testWidgets('the back arrow goes to Profile', (tester) async {
    final router = await pumpPage(tester);

    await tester.tap(find.byKey(const Key('page_back')));
    await tester.pumpAndSettle();

    expect(find.text('Profile page'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/profile');
  });
}
