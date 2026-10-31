import 'package:doormer/src/features/profile/presentation/pages/invite_page.dart';
import 'package:go_router/go_router.dart';

/// The route of an invite link, `/add/<code>`, kept apart from WebRouter so
/// a test can load it.
///
/// Only a student who isn't signed in sees its page: the router's guard
/// keeps the code, and sends a signed-in student on to the code's check at
/// `/profile/add/<code>`.
final List<GoRoute> inviteRoutes = [
  GoRoute(
    path: '/add/:code',
    builder: (context, state) => const InvitePage(),
  ),
];
