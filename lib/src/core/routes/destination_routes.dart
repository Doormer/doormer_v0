import 'package:doormer/src/core/routes/destination_shell.dart';
import 'package:doormer/src/core/routes/question_solution_routes.dart';
import 'package:doormer/src/features/collection/presentation/pages/collection_page.dart';
import 'package:doormer/src/features/profile/presentation/pages/profile_page.dart';
import 'package:doormer/src/features/questions/presentation/pages/ask_by_photo_page.dart';
import 'package:doormer/src/features/questions/presentation/pages/saved_questions_page.dart';
import 'package:go_router/go_router.dart';

/// The routes of the pages on the nav bar, one per destination that has a page
/// so far: Saved, Solve, Cards, and Profile.
///
/// They're tabs of one [DestinationShell]: the bar is built once, and each page
/// stays alive while another is shown, so switching back shows it as it was
/// left, with no reload. Switching cross-fades the pages. Saved and Cards load
/// as soon as the shell opens, so even a first visit has no spinner.
///
/// A solution opens over the nav bar from its tab, at
/// `<tab>/<questionId>/solution`, with every tab still alive under it.
///
/// Kept apart from `WebRouter` so a test can load them: the router also holds
/// the auth pages, which only compile for the browser. A router that loads them
/// is built with `rootNavigatorKey` as its `navigatorKey`.
final List<RouteBase> destinationRoutes = [
  DestinationShell.route(
    // In the order of DestinationShell.destinations.
    branches: [
      // Loaded as soon as the shell opens, so the first visit opens on the
      // questions rather than a spinner. That visit still refreshes quietly,
      // on purpose: it shows any question solved since the shell opened.
      StatefulShellBranch(preload: true, routes: [
        GoRoute(
          path: '/saved',
          builder: (context, state) => const SavedQuestionsPage(),
          routes: [solutionRoute(tabLocation: '/saved', tabName: 'Saved')],
        ),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/questions/photo',
          builder: (context, state) {
            final extra = state.extra;
            return AskByPhotoPage(
              photoSourceOptionsRequest:
                  extra is ShowPhotoSourceOptionsOnOpen ? extra : null,
            );
          },
          routes: [
            solutionRoute(tabLocation: '/questions/photo', tabName: 'Solve'),
          ],
        ),
      ]),
      // Loaded as soon as the shell opens, so the first visit opens on the
      // deck list rather than a spinner. That visit still refreshes quietly,
      // on purpose: it shows the quarks earned since the shell opened.
      StatefulShellBranch(preload: true, routes: [
        GoRoute(
          path: '/collection',
          builder: (context, state) => const CollectionPage(),
        ),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ]),
    ],
  ),
];
