import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Keeps track of the dialogs and sheets that are open, so the app shell can
/// dim the margins beside the column to match their scrim.
class PopupRouteTracker extends NavigatorObserver with ChangeNotifier {
  final List<PopupRoute<dynamic>> _open = [];

  bool get hasOpenPopup => _open.isNotEmpty;

  /// The scrim colour of the top popup, so the margins match it.
  Color get barrierColor =>
      (_open.isEmpty ? null : _open.last.barrierColor) ?? Colors.black54;

  /// Closes the top popup, as a tap on its own scrim would.
  void dismissTop() {
    if (_open.isEmpty) return;
    final top = _open.last;
    if (!top.barrierDismissible) return;
    top.navigator?.maybePop();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) {
      _open.add(route);
      _changed();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _forget(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _forget(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _forget(oldRoute);
    if (newRoute != null) didPush(newRoute, null);
  }

  void _forget(Route<dynamic> route) {
    if (_open.remove(route)) _changed();
  }

  // The navigator reports some changes mid-build; listeners rebuild the shell,
  // which must wait for the frame to finish.
  void _changed() {
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) => notifyListeners());
    } else {
      notifyListeners();
    }
  }
}
