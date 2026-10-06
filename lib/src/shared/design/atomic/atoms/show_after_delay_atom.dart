import 'dart:async';

import 'package:flutter/widgets.dart';

/// Shows [child] only once [delay] has passed since this first appeared.
///
/// Before that it shows nothing and takes no space.
class ShowAfterDelayAtom extends StatefulWidget {
  final Duration delay;
  final Widget child;

  const ShowAfterDelayAtom({
    super.key,
    required this.delay,
    required this.child,
  });

  @override
  State<ShowAfterDelayAtom> createState() => _ShowAfterDelayAtomState();
}

class _ShowAfterDelayAtomState extends State<ShowAfterDelayAtom> {
  late final Timer _timer;
  bool _due = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () => setState(() => _due = true));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _due ? widget.child : const SizedBox.shrink();
}
