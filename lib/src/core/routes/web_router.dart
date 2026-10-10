import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/routes/question_solution_routes.dart';
import 'package:doormer/src/core/routes/popup_route_tracker.dart';
import 'package:doormer/src/core/routes/route_guard.dart';
import 'package:doormer/src/core/utils/token_storage/token_storage.dart';
import 'package:doormer/src/features/auth/presentation/pages/login_page.dart';
import 'package:doormer/src/features/auth/presentation/pages/signup_page.dart';
import 'package:doormer/src/core/routes/destination_routes.dart';
import 'package:doormer/src/features/registration/presentation/pages/candidate_registration.dart';
import 'package:doormer/src/features/registration/presentation/pages/registration_complete_page.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/shared/widget/not_found_page.dart';

import 'package:go_router/go_router.dart';

/*

WebRouter defines the routing structure and logic specifically for the web platform.

*/

class WebRouter {
  static final PopupRouteTracker popupRoutes = PopupRouteTracker();

  static final GoRouter router = GoRouter(
    initialLocation: '/auth',
    redirect: (context, state) async {
      final tokens = serviceLocator<TokenStorage>();
      return redirectFor(
        state.uri.path,
        isSignedIn: hasSignedInSession(
          accessToken: await tokens.getAccessToken(),
          refreshToken: await tokens.getRefreshToken(),
        ),
      );
    },
    observers: [popupRoutes],
    routes: [
      // Authentication Routes (Only for users NOT logged in)
      GoRoute(
        path: '/auth',
        builder: (context, state) => const SignUpPageWeb(),
        routes: [
          GoRoute(
            path: 'signup',
            builder: (context, state) => const SignUpPageWeb(),
          ),
          GoRoute(
            path: 'login',
            builder: (context, state) => const LoginPageWeb(),
          ),
          GoRoute(
              path: 'registration',
              builder: (context, state) => const CandidateRegistrationPage()),
          GoRoute(
              path: 'registration-complete',
              builder: (context, state) => const RegistrationCompletePage()),
        ],
      ),
      ...destinationRoutes,
      ...questionSolutionRoutes,
    ],
    errorBuilder: (context, state) {
      AppLogger.warn('Page not found: ${state.uri.path}');
      return NotFoundPage(onGoHome: () => context.go('/'));
    },
  );
}
