import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/pages/question_solution_page.dart';
import 'package:go_router/go_router.dart';

/// Solution reader routes, kept apart from WebRouter so ordering can be tested.
/// The sample route must stay before the id route, or `sample` becomes a
/// question id and the bundled sample disappears.
final List<GoRoute> questionSolutionRoutes = [
  GoRoute(
    path: '/questions/sample/solution',
    builder: (context, state) => const QuestionSolutionPage(),
  ),
  GoRoute(
    path: '/questions/:questionId/solution',
    builder: (context, state) {
      final extra = state.extra;
      return QuestionSolutionPage(
        questionId: state.pathParameters['questionId'],
        solvedState: extra is AskByPhotoSolved ? extra : null,
      );
    },
  ),
];
