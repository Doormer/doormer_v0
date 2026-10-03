import 'package:flutter/widgets.dart';

/// Scrolls [child] into view whenever [trigger] changes to a non-null value.
///
/// For content that appears below the fold in response to something the user
/// did, like an error under a tall photo.
class RevealOnChangeAtom extends StatefulWidget {
  final Object? trigger;
  final Widget child;

  const RevealOnChangeAtom({
    super.key,
    required this.trigger,
    required this.child,
  });

  @override
  State<RevealOnChangeAtom> createState() => _RevealOnChangeAtomState();
}

class _RevealOnChangeAtomState extends State<RevealOnChangeAtom> {
  @override
  void didUpdateWidget(covariant RevealOnChangeAtom oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != null && widget.trigger != oldWidget.trigger) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.1,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
