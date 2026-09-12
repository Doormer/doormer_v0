import 'package:doormer/src/features/auth/presentation/pages/login_page.dart';
import 'package:doormer/src/features/auth/presentation/pages/signup_page.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/pages/ask_by_photo_page.dart';
import 'package:doormer/src/features/questions/presentation/pages/question_solution_page.dart';
import 'package:doormer/src/features/registration/presentation/pages/candidate_registration.dart';
import 'package:doormer/src/features/registration/presentation/pages/registration_complete_page.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

/*

WebRouter defines the routing structure and logic specifically for the web platform.

*/

class WebRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/auth',
    routes: [
      // Authentication Routes (Only for users NOT logged in)
      GoRoute(
        path: '/auth',
        builder: (context, state) => SignUpPageWeb(),
        routes: [
          GoRoute(path: 'signup', builder: (context, state) => SignUpPageWeb()),
          GoRoute(
            path: 'login',
            builder: (context, state) => LoginPageWeb(),
          ),
          GoRoute(
              path: 'registration',
              builder: (context, state) => const CandidateRegistrationPage()),
          GoRoute(
              path: 'registration-complete',
              builder: (context, state) => const RegistrationCompletePage()),
        ],
      ),
      GoRoute(
        path: '/questions/photo',
        builder: (context, state) => const AskByPhotoPage(),
      ),
      GoRoute(
        path: '/questions/:questionId/solution',
        builder: (context, state) {
          final extra = state.extra;
          return QuestionSolutionPage(
            questionId: state.pathParameters['questionId'] ?? '',
            solvedState: extra is AskByPhotoSolved ? extra : null,
          );
        },
      ),
    ],
    errorBuilder: (context, state) {
      AppLogger.warn('Page not found: ${state.fullPath}');
      return const Scaffold(
        body: Center(child: Text('Page not found!')),
      );
    },
  );
}
