import 'package:doormer/src/core/routes/popup_route_tracker.dart';
import 'package:go_router/go_router.dart';

import 'web_router_stub.dart' if (dart.library.js_interop) 'web_router.dart'
    as platform_router;

/*

AppRouter serves as the main entry point for the application's routing system. 
It determines whether to use the mobile or web router based on the platform (kIsWeb) 
and delegates the routing setup accordingly.

*/

class AppRouter {
  static GoRouter get router => platform_router.WebRouter.router;

  static PopupRouteTracker get popupRoutes =>
      platform_router.WebRouter.popupRoutes;
}
