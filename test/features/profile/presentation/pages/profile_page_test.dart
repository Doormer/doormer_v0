import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/profile/domain/usecase/sign_out_usecase.dart';
import 'package:doormer/src/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:doormer/src/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

  late _FakeSessionService session;

  setUp(() {
    session = _FakeSessionService();
    serviceLocator.registerFactory<ProfileBloc>(
      () => ProfileBloc(signOut: SignOutUseCase(session)),
    );
  });

  tearDown(() async {
    await serviceLocator.reset();
  });

  Future<void> pumpProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/saved',
          builder: (context, state) => const Text('saved'),
        ),
        GoRoute(
          path: '/auth/login',
          builder: (context, state) => const Text('login'),
        ),
      ],
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
  }

  testWidgets('shows profile content', (tester) async {
    await pumpProfile(tester);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == 'Profile' &&
            (widget.style?.debugLabel?.contains('headlineMedium') ?? false),
      ),
      findsOneWidget,
    );
    expect(find.text('More profile options are coming soon.'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('signs out and opens login', (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(session.logouts, 1);
    expect(find.text('login'), findsOneWidget);
  });

  testWidgets('Saved opens the saved questions', (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.byIcon(Icons.bookmark_outline));
    await tester.pumpAndSettle();

    expect(find.text('saved'), findsOneWidget);
  });
}
