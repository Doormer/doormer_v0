import 'dart:async';

import 'package:flutter/material.dart';

/// Time since this first appeared, as `m:ss`, updated every second.
///
/// It reads the clock rather than counting ticks: browsers slow timers down
/// in background tabs, and the time must still be right when the student
/// comes back.
class ElapsedTimeAtom extends StatefulWidget {
  final TextStyle? style;

  /// Reads the time. Tests pass their own clock.
  final DateTime Function() now;

  const ElapsedTimeAtom({super.key, this.style, this.now = DateTime.now});

  @override
  State<ElapsedTimeAtom> createState() => _ElapsedTimeAtomState();
}

class _ElapsedTimeAtomState extends State<ElapsedTimeAtom> {
  late final DateTime _start;
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _start = widget.now();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var elapsed = widget.now().difference(_start);
    if (elapsed.isNegative) elapsed = Duration.zero;
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return Text('${elapsed.inMinutes}:$seconds', style: widget.style);
  }
}
