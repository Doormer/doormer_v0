import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/shared/design/atomic/atoms/punch_atom.dart';
import 'package:flutter/material.dart';

import '../atoms/quark_balance_atom.dart';
import 'shattered_copy_molecule.dart';

/// The student's quarks, counting in what a shatter pays.
///
/// When the balance rises, it holds while the shatter's quark dots are on
/// their way, counts up while they land, and punches once as the last one
/// lands. It keeps to the shatter's clock, [ShatteredCopyMolecule.duration]
/// and [ShatteredCopyMolecule.quarkDotsLanding], so the count and the quark
/// dots arrive together. A fall, or any change with motion off, shows at once.
class QuarkBalanceMolecule extends StatefulWidget {
  final int quarkBalance;

  /// Put on the quark dot, so a card window can aim a shatter's quark dots
  /// at it.
  final Key? dotKey;

  const QuarkBalanceMolecule({
    super.key,
    required this.quarkBalance,
    this.dotKey,
  });

  @override
  State<QuarkBalanceMolecule> createState() => _QuarkBalanceMoleculeState();
}

class _QuarkBalanceMoleculeState extends State<QuarkBalanceMolecule>
    with SingleTickerProviderStateMixin {
  /// Runs a rise from 0 to 1, in step with the shatter that paid it.
  late final AnimationController _countIn;

  /// The balance the rise being counted in started from.
  int _countFrom = 0;

  /// How many rises have been counted in. The balance punches when this goes
  /// up.
  int _rises = 0;

  @override
  void initState() {
    super.initState();
    _countIn = AnimationController(
      vsync: this,
      duration: ShatteredCopyMolecule.duration,
    );
  }

  @override
  void didUpdateWidget(QuarkBalanceMolecule oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.quarkBalance;
    final after = widget.quarkBalance;
    if (after > before && MotionPolicy.of(context)) {
      // A rise still counting in jumps to its end, and this one counts up
      // from there.
      _countFrom = before;
      _rises++;
      _countIn.forward(from: 0);
    } else if (after != before) {
      _countIn.stop();
    }
  }

  @override
  void dispose() {
    _countIn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _countIn,
      builder: (context, _) {
        final landed = _countIn.isAnimating
            ? ShatteredCopyMolecule.quarkDotsLanding.transform(_countIn.value)
            : 1.0;
        final shown = landed < 1
            ? _countFrom + ((widget.quarkBalance - _countFrom) * landed).ceil()
            : widget.quarkBalance;
        return PunchAtom(
          // One punch per rise, as its last quark dot lands. A punch at every
          // quark dot would restart every frame or two, and the balance would
          // flicker.
          trigger: landed < 1 ? _rises - 1 : _rises,
          child: QuarkBalanceAtom(quarkBalance: shown, dotKey: widget.dotKey),
        );
      },
    );
  }
}
