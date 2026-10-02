import 'package:doormer/src/features/collection/presentation/pages/collection_page.dart';
import 'package:doormer/src/features/questions/presentation/pages/ask_by_photo_page.dart';
import 'package:go_router/go_router.dart';

/// The routes of the pages on the nav bar, one per destination that has a
/// page so far.
///
/// They're tabs, so they swap in place with no page transition. The default
/// one slid the whole page in, bar and all, and two bars crossed mid-switch.
///
/// Kept apart from `WebRouter` so a test can load them: the router also holds
/// the auth pages, which only compile for the browser.
final List<GoRoute> destinationRoutes = [
  GoRoute(
    path: '/questions/photo',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const AskByPhotoPage(),
    ),
  ),
  GoRoute(
    path: '/collection',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const CollectionPage(),
    ),
  ),
];
