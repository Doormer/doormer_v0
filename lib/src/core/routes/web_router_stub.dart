import 'package:doormer/src/core/routes/popup_route_tracker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WebRouter {
  static final PopupRouteTracker popupRoutes = PopupRouteTracker();

  static final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SizedBox.shrink(),
      ),
    ],
  );
}
