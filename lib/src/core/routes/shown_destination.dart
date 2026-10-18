import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:flutter/widgets.dart';

/// Tells the tab pages, which all stay alive inside the destination shell,
/// which one is on screen.
class ShownDestination extends InheritedWidget {
  final AppDestination destination;

  /// Goes up by one each time the student taps the nav item of the page they
  /// are already on.
  final int reselections;

  const ShownDestination({
    super.key,
    required this.destination,
    required this.reselections,
    required super.child,
  });

  /// Null outside the shell, where a page is the only thing on screen.
  static ShownDestination? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShownDestination>();

  /// Whether [destination]'s page is on screen. Outside the shell it always is.
  ///
  /// For callbacks: it doesn't rebuild the caller when the answer changes.
  static bool isShown(BuildContext context, AppDestination destination) {
    final shown = context.getInheritedWidgetOfExactType<ShownDestination>();
    return shown == null || shown.destination == destination;
  }

  @override
  bool updateShouldNotify(ShownDestination oldWidget) =>
      destination != oldWidget.destination ||
      reselections != oldWidget.reselections;
}

/// Tells a tab page when the student comes back to it, and when they tap its
/// nav item while already on it.
///
/// Both run after the frame, so they may show a sheet or navigate.
class DestinationListener extends StatefulWidget {
  final AppDestination destination;

  /// The student switched to [destination] from another page.
  final VoidCallback? onReturnedTo;

  /// The student tapped [destination]'s nav item while on it.
  final VoidCallback? onReselected;

  final Widget child;

  const DestinationListener({
    super.key,
    required this.destination,
    this.onReturnedTo,
    this.onReselected,
    required this.child,
  });

  @override
  State<DestinationListener> createState() => _DestinationListenerState();
}

class _DestinationListenerState extends State<DestinationListener> {
  ShownDestination? _last;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shown = ShownDestination.maybeOf(context);
    final last = _last;
    _last = shown;
    if (shown == null || last == null) return;
    if (shown.destination != widget.destination) return;

    final callback = last.destination != widget.destination
        ? widget.onReturnedTo
        : last.reselections != shown.reselections
            ? widget.onReselected
            : null;
    if (callback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
