import 'package:doormer/src/features/auth/presentation/pages/signup_page.dart';
import 'package:doormer/src/features/registration/presentation/pages/candidate_registration.dart';
import 'package:doormer/src/features/registration/presentation/pages/registration_complete_page.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

/*

WebRouter defines the routing structure and logic specifically for the web platform.

*/

class WebRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/auth/registration',
    routes: [
      // Authentication Routes (Only for users NOT logged in)
      GoRoute(
        path: '/auth',
        builder: (context, state) => SignUpPageWeb(),
        routes: [
          GoRoute(path: 'signup', builder: (context, state) => SignUpPageWeb()),
          GoRoute(
              path: 'registration',
              builder: (context, state) => const CandidateRegistrationPage()),
          GoRoute(
              path: 'registration-complete',
              builder: (context, state) => const RegistrationCompletePage())
        ],
      ),
    ],
    errorBuilder: (context, state) {
      debugPrint('Page not found: ${state.fullPath}');
      return const Scaffold(
        body: Center(child: Text('Page not found!')),
      );
    },
  );
}
