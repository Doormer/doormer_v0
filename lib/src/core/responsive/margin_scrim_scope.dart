import 'package:doormer/src/core/routes/popup_route_tracker.dart';
import 'package:flutter/material.dart';

class MarginScrimScope extends StatefulWidget {
  final PopupRouteTracker tracker;
  final Color barrierColor;
  final VoidCallback onDismiss;
  final Widget child;

  const MarginScrimScope({
    super.key,
    required this.tracker,
    required this.barrierColor,
    required this.onDismiss,
    required this.child,
  });

  @override
  State<MarginScrimScope> createState() => _MarginScrimScopeState();
}

class _MarginScrimScopeState extends State<MarginScrimScope> {
  @override
  void initState() {
    super.initState();
    _openOverlay();
  }

  @override
  void didUpdateWidget(MarginScrimScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tracker != widget.tracker) {
      oldWidget.tracker.closeOverlay(this);
    }
    _openOverlay();
  }

  @override
  void dispose() {
    widget.tracker.closeOverlay(this);
    super.dispose();
  }

  void _openOverlay() {
    widget.tracker.openOverlay(
      this,
      barrierColor: widget.barrierColor,
      onDismiss: widget.onDismiss,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
