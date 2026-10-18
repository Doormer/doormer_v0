import 'package:doormer/src/core/routes/root_navigator_key.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/pages/question_solution_page.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// The route of a solution opened from a tab, at `<tab>/<questionId>/solution`.
///
/// It opens on [rootNavigatorKey], over the nav bar, so every tab stays alive
/// under it and closing it shows the tab as it was left. A finished solve
/// hands its solution over in `extra`.
GoRoute solutionRoute({required String tabLocation, required String tabName}) {
  return GoRoute(
    path: ':questionId/solution',
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) {
      final questionId = state.pathParameters['questionId'];
      final extra = state.extra;
      return QuestionSolutionPage(
        // go_router names the page after this route's pattern, so the
        // solutions of two questions would share one page, and the second
        // would go on showing the first. The key gives each its own.
        key: ValueKey(questionId),
        questionId: questionId,
        solvedState: extra is AskByPhotoSolved ? extra : null,
        tabLocation: tabLocation,
        tabName: tabName,
      );
    },
  );
}

/// The solution routes outside the tabs, kept apart from WebRouter so their
/// order can be tested: the bundled sample, and the address solutions had
/// before they moved under their tab. The sample route must stay before the id
/// route, or `sample` becomes a question id and the bundled sample disappears.
final List<GoRoute> questionSolutionRoutes = [
  GoRoute(
    path: '/questions/sample/solution',
    builder: (context, state) => const QuestionSolutionPage(),
  ),
  // Saved lists every solved question, so links to the old address open the
  // solution there.
  GoRoute(
    path: '/questions/:questionId/solution',
    redirect: (context, state) {
      // go_router hands path parameters over decoded.
      final questionId =
          Uri.encodeComponent(state.pathParameters['questionId']!);
      return '/saved/$questionId/solution';
    },
  ),
];
