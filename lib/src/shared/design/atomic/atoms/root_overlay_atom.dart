import 'package:flutter/widgets.dart';

/// Shows [child] where it stands and, when there is one, [overlayChild] above
/// the whole app, nav bar included: in an entry of its own on the root
/// overlay.
///
/// Unlike an `OverlayPortal`, whose semantics stay where the portal sits, an
/// entry's semantics come after everything already on screen, so a
/// [BlockSemantics] in [overlayChild] hides the rest of the app from screen
/// readers too. Whether to hide it is up to the caller.
///
/// [overlayChild] appears and goes a frame after it changes: the overlay
/// can't change while the widgets around this one build.
class RootOverlayAtom extends StatefulWidget {
  final Widget? overlayChild;
  final Widget child;

  const RootOverlayAtom({
    super.key,
    required this.overlayChild,
    required this.child,
  });

  @override
  State<RootOverlayAtom> createState() => _RootOverlayAtomState();
}

class _RootOverlayAtomState extends State<RootOverlayAtom> {
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    _syncAfterFrame();
  }

  @override
  void didUpdateWidget(RootOverlayAtom oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.overlayChild != oldWidget.overlayChild) _syncAfterFrame();
  }

  void _syncAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final overlayChild = widget.overlayChild;
      if (overlayChild == null) {
        _removeEntry();
      } else if (_entry == null) {
        _entry = OverlayEntry(
          builder: (_) => widget.overlayChild ?? const SizedBox.shrink(),
        );
        Overlay.of(context, rootOverlay: true).insert(_entry!);
      } else {
        _entry!.markNeedsBuild();
      }
    });
  }

  void _removeEntry() {
    _entry
      ?..remove()
      ..dispose();
    _entry = null;
  }

  @override
  void dispose() {
    _removeEntry();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
