import 'package:doormer/src/core/routes/destination_shell.dart';
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
/// left, with no reload.
///
/// Kept apart from `WebRouter` so a test can load them: the router also holds
/// the auth pages, which only compile for the browser.
final List<RouteBase> destinationRoutes = [
  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        DestinationShell(navigationShell: navigationShell),
    // In the order of DestinationShell.branches.
    branches: [
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/saved',
          builder: (context, state) => const SavedQuestionsPage(),
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
        ),
      ]),
      StatefulShellBranch(routes: [
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
