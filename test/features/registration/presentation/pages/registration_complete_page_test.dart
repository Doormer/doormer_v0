import 'package:doormer/src/core/config/app_config.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/registration/presentation/pages/registration_complete_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late GoRouter router;
  final opened = <Uri>[];

  Future<void> pumpPage(WidgetTester tester) async {
    opened.clear();
    router = GoRouter(
      initialLocation: '/auth/registration-complete',
      routes: [
        GoRoute(
          path: '/auth/registration-complete',
          builder: (_, __) => RegistrationCompletePage(
            openSurvey: (uri) async {
              opened.add(uri);
              return true;
            },
          ),
        ),
        GoRoute(
          path: '/questions/photo',
          builder: (_, __) => const Scaffold(body: Text('Solve page')),
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

  testWidgets('welcomes the student in and sends them to Solve',
      (tester) async {
    await pumpPage(tester);

    expect(find.text("You're in!"), findsOneWidget);
    await tester.tap(find.text('Solve a question'));
    await tester.pumpAndSettle();

    expect(find.text('Solve page'), findsOneWidget);
  });

  testWidgets('still offers the survey', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Take a 2-minute survey'));
    await tester.pump();

    expect(opened, [Uri.parse(AppConfig.surveyURL)]);
  });
}
