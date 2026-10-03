import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Keeps track of dialogs, sheets, and page overlays that are open, so the app
/// shell can dim the margins beside the column to match their scrim.
class PopupRouteTracker extends NavigatorObserver with ChangeNotifier {
  final List<_BarrierEntry> _open = [];

  bool get hasOpenPopup => _open.isNotEmpty;

  /// The scrim colour of the top popup or page overlay, so the margins match
  /// it.
  Color get barrierColor =>
      _open.isEmpty ? Colors.black54 : _open.last.barrierColor;

  void openOverlay(
    Object owner, {
    required Color barrierColor,
    required VoidCallback onDismiss,
  }) {
    final index = _open.indexWhere(
      (entry) => entry is _OverlayEntry && entry.owner == owner,
    );
    final entry = _OverlayEntry(
      owner: owner,
      barrierColor: barrierColor,
      onDismiss: onDismiss,
    );
    if (index == -1) {
      _open.add(entry);
    } else {
      _open[index] = entry;
    }
    _changed();
  }

  void closeOverlay(Object owner) {
    final before = _open.length;
    _open.removeWhere(
      (entry) => entry is _OverlayEntry && entry.owner == owner,
    );
    if (_open.length != before) _changed();
  }

  /// Closes the top popup or page overlay, as a tap on its own scrim would.
  void dismissTop() {
    if (_open.isEmpty) return;
    _open.last.dismiss();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) {
      _open.add(_PopupEntry(route));
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
    final before = _open.length;
    _open.removeWhere(
      (entry) => entry is _PopupEntry && entry.route == route,
    );
    if (_open.length != before) _changed();
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

abstract interface class _BarrierEntry {
  Color get barrierColor;

  void dismiss();
}

class _PopupEntry implements _BarrierEntry {
  final PopupRoute<dynamic> route;

  _PopupEntry(this.route);

  @override
  Color get barrierColor => route.barrierColor ?? Colors.black54;

  @override
  void dismiss() {
    if (!route.barrierDismissible) return;
    route.navigator?.maybePop();
  }
}

class _OverlayEntry implements _BarrierEntry {
  final Object owner;
  @override
  final Color barrierColor;
  final VoidCallback onDismiss;

  _OverlayEntry({
    required this.owner,
    required this.barrierColor,
    required this.onDismiss,
  });

  @override
  void dismiss() => onDismiss();
}
