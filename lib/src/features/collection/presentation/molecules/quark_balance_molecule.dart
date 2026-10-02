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
/// dots arrive together.
///
/// While the quark dots land, the balance lights up. It lifts itself above
/// everything on screen, such as a card window and its dark overlay, glows
/// amber, and settles back shortly after the last quark dot lands. A fall, or
/// any change with motion off, shows at once.
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
  static double get _shatterMs =>
      ShatteredCopyMolecule.duration.inMicroseconds / 1000;

  /// When the first quark dot lands, in milliseconds into a rise.
  static double get _firstLandsMs =>
      _shatterMs * ShatteredCopyMolecule.quarkDotsLanding.begin;

  /// When the last quark dot lands, in milliseconds into a rise.
  static double get _lastLandsMs =>
      _shatterMs * ShatteredCopyMolecule.quarkDotsLanding.end;

  /// How long the glow takes to come up once the first quark dot lands.
  static const double _lightUpMs = 50;

  /// How long the balance stays lit after the last quark dot lands.
  static const double _stayLitMs = 300;

  /// How long a lit balance takes to settle back.
  static const double _settleMs = 400;

  /// Runs a whole rise: the quark dots flying and landing, then the balance
  /// staying lit and settling back.
  late final AnimationController _rise;

  /// The balance the rise being counted in started from.
  int _countFrom = 0;

  /// How many rises have been counted in. The balance punches when this goes
  /// up.
  int _rises = 0;

  /// How much the balance glowed when this rise began. It is above 0 only
  /// when a rise arrives while the balance is still lit.
  double _glowAtStart = 0;

  /// Pins the lifted balance onto the balance in place.
  final LayerLink _link = LayerLink();

  /// The lit copy of the balance, drawn above everything on screen while the
  /// balance glows.
  OverlayEntry? _liftedBalance;

  @override
  void initState() {
    super.initState();
    _rise = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: (_lastLandsMs + _stayLitMs + _settleMs).round()),
    )
      ..addListener(_onTick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _dropLiftedBalance();
      });
  }

  @override
  void didUpdateWidget(QuarkBalanceMolecule oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.quarkBalance;
    final after = widget.quarkBalance;
    if (after > before && MotionPolicy.of(context)) {
      // A rise still counting in jumps to its end, and this one counts up
      // from there. A lit balance stays lit until this rise's dots land.
      _countFrom = before;
      _glowAtStart = _glow;
      _rises++;
      _rise.forward(from: 0);
    } else if (after != before) {
      _rise.stop();
      _dropLiftedBalance();
    }
  }

  @override
  void dispose() {
    _dropLiftedBalance();
    _rise.dispose();
    super.dispose();
  }

  double get _elapsedMs =>
      (_rise.lastElapsedDuration ?? Duration.zero).inMicroseconds / 1000;

  /// How much of the rise's quarks have landed, from 0 to 1.
  double get _landed => _rise.isAnimating
      ? ShatteredCopyMolecule.quarkDotsLanding
          .transform((_elapsedMs / _shatterMs).clamp(0.0, 1.0))
      : 1.0;

  /// How much the balance glows, from 0 to 1.
  double get _glow {
    if (!_rise.isAnimating) return 0;
    final ms = _elapsedMs;
    if (ms < _firstLandsMs) return _glowAtStart;
    if (ms < _firstLandsMs + _lightUpMs) {
      final t = (ms - _firstLandsMs) / _lightUpMs;
      return _glowAtStart + (1 - _glowAtStart) * t;
    }
    final settleFrom = _lastLandsMs + _stayLitMs;
    if (ms < settleFrom) return 1;
    // Drops quickly, then lingers.
    return 1 -
        Curves.easeOut
            .transform(((ms - settleFrom) / _settleMs).clamp(0.0, 1.0));
  }

  /// Runs on the rise's ticks. Lifts the balance when it first lights up, and
  /// redraws the lifted copy after that. The overlay is outside this widget,
  /// so it may only be touched between builds, as ticks are.
  void _onTick() {
    // Starting a rise also notifies, while this widget is building.
    if (!_rise.isAnimating) return;
    final lifted = _liftedBalance;
    if (lifted != null) {
      lifted.markNeedsBuild();
      return;
    }
    if (_glow == 0) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _liftedBalance = OverlayEntry(builder: (_) => _buildLiftedBalance());
    overlay.insert(_liftedBalance!);
  }

  void _dropLiftedBalance() {
    _liftedBalance
      ?..remove()
      ..dispose();
    _liftedBalance = null;
  }

  Widget _balance({double glow = 0, Key? dotKey}) {
    final landed = _landed;
    return PunchAtom(
      // One punch per rise, as its last quark dot lands. A punch at every
      // quark dot would restart every frame or two, and the balance would
      // flicker.
      trigger: landed < 1 ? _rises - 1 : _rises,
      child: QuarkBalanceAtom(
        quarkBalance: landed < 1
            ? _countFrom + ((widget.quarkBalance - _countFrom) * landed).ceil()
            : widget.quarkBalance,
        glow: glow,
        dotKey: dotKey,
      ),
    );
  }

  /// Built in the overlay, so it reads only this state, never [context].
  Widget _buildLiftedBalance() {
    final glow = _glow;
    return Positioned(
      key: const Key('quark-balance-lifted'),
      left: 0,
      top: 0,
      right: 0,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            child: Align(
              alignment: Alignment.topLeft,
              // Gives the text the theme's style, as on the page.
              child: Material(
                type: MaterialType.transparency,
                child: Opacity(opacity: glow, child: _balance(glow: glow)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The target is outermost: an Opacity at 0 skips painting its child, and
    // the lifted balance hides when its target is not painted.
    return CompositedTransformTarget(
      link: _link,
      child: AnimatedBuilder(
        animation: _rise,
        builder: (context, _) => Opacity(
          opacity: 1 - _glow,
          child: _balance(dotKey: widget.dotKey),
        ),
      ),
    );
  }
}
