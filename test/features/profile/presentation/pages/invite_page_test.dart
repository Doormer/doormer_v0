import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/profile/presentation/pages/invite_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<void> pumpInvite(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/add/K7QM2XPA',
      routes: [
        GoRoute(path: '/add/:code', builder: (_, __) => const InvitePage()),
        GoRoute(
          path: '/auth/signup',
          builder: (_, __) => const Scaffold(body: Text('sign up page')),
        ),
        GoRoute(
          path: '/auth/login',
          builder: (_, __) => const Scaffold(body: Text('log in page')),
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
  }

  testWidgets('says a friend invited them, without naming the friend',
      (tester) async {
    await pumpInvite(tester);

    expect(find.text('A friend invited you to Doormer'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('Sign up opens sign-up', (tester) async {
    await pumpInvite(tester);

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('sign up page'), findsOneWidget);
  });

  testWidgets('Log in opens log-in', (tester) async {
    await pumpInvite(tester);

    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('log in page'), findsOneWidget);
  });
}
