import 'package:flutter/widgets.dart';

/// The key of the router's own navigator, the one above the nav bar's shell.
///
/// A route under a tab that must cover the nav bar, such as a solution, opens
/// on it, so the tabs stay alive underneath. Every router that loads
/// `destinationRoutes` is built with it as its `navigatorKey`.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
