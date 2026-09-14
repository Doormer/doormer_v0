import 'dart:math' as math;

import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entity/card_rarity.dart';
import '../../domain/entity/draw_outcome.dart';
import '../atoms/card_back_atom.dart';
import '../atoms/collectible_card_atom.dart';
import '../params/reveal_params.dart';

/// The draw: a card lands face-down, tells its rarity, turns, and settles.
///
/// One controller drives four phases over [totalDuration]:
/// **back** (0.00-0.12, still), **tell** (0.12-0.40, the glow builds *before*
/// the card turns — a rare is felt a beat early), **flip** (0.40-0.66, the
/// turn itself) and **landing** (0.66-1.00, the flourish settles).
///
/// A common draw gets the ground shadow and the lift of the turn — physics,
/// not flourish — and nothing else. That restraint is the whole point: if
/// every draw bloomed, none would feel like anything.
class CardRevealOrganism extends StatefulWidget {
  static const Duration totalDuration = Duration(milliseconds: 1600);

  /// Phase boundaries, shared with [CardRevealState] so every layer's shape
  /// function is built from the same table rather than its own guess.
  static const double backEnd = 0.12;
  static const double tellEnd = 0.40;
  static const double flipEnd = 0.66;

  final RevealParams params;

  const CardRevealOrganism({super.key, required this.params});

  /// Cards in the fan. Below the cap the fan *is* the count and can be read
  /// without the badge; at four it stops meaning a number and means *a pile*.
  /// Four is also the widest fan that fits a phone card without the outer
  /// cards leaving the frame.
  static int fanCountFor(int copies) => math.min(math.max(copies, 1), 4);

  /// How wide the glow should be at a given rotation, where 0 is face-down,
  /// 0.5 is edge-on and 1 is face-up.
  ///
  /// **This is the ghost-rectangle fix.** A glow that keeps its width while the
  /// card foreshortens is plainly visible at 90°, when the card itself has no
  /// width at all. Driving it from the same value collapses both together.
  static double glowScaleX(double rotation) {
    final foreshorten = (math.cos(rotation * math.pi)).abs();
    return math.max(foreshorten, 0.02);
  }

  @override
  State<CardRevealOrganism> createState() => CardRevealState();
}

class CardRevealState extends State<CardRevealOrganism>
    with TickerProviderStateMixin {
  static const double _cardDesignWidth = 126;

  late final AnimationController _controller;

  /// Spins the rays slowly and continuously. A separate controller because
  /// this loop keeps turning long after [_controller] has finished — the
  /// rays are ambient, not part of the one-shot reveal.
  late final AnimationController _rayController;

  /// 0 face-down, 1 face-up.
  double get rotation => _flip.value;

  late final Animation<double> _flip;

  /// The headline's own arrival, after the flip has finished.
  late final Animation<double> _landing;

  /// How far the headline has arrived, 0 hidden to 1 fully shown.
  double get headlineOpacity => _landing.value;

  Rarity get _rarity => widget.params.outcome.card.rarity;

  bool get _isRare => _rarity == Rarity.rare;

  bool get _flourishWanted => _isRare && MotionPolicy.idle(context);

  /// Whether the decorative ray loop is actually spinning right now. Exposed
  /// so a test can prove reduced motion stops it, instead of reaching into
  /// private state.
  bool get flourishRunning => _rayController.isAnimating;

  /// The glow's opacity over the whole reveal, transcribed from the mockup's
  /// own keyframes rather than scaled from a single shape.
  ///
  /// The two tiers are not the same curve at different volumes — they differ
  /// in *when* they happen. The rare glow (`gO`) starts building at 26% and is
  /// full at 38%, before the card has turned: that IS the tell, and the
  /// anticipation mockup describes it as "the brass glow builds before the
  /// card resolves, so you know it is rare a moment early". The common glow
  /// (`cgO`) is flat zero until 40% and only appears as the card lands. A
  /// common draw has no tell, because a tell that every draw had would tell
  /// you nothing.
  double get glowOpacity {
    final t = _controller.value;
    if (_isRare) {
      return _piecewise(
        t,
        const [0.0, 0.119, 0.26, 0.38, 0.478, 0.66, 0.779, 1.0],
        const [0.0, 0.0, 0.5, 1.0, 0.5, 1.0, 0.9, 0.85],
      );
    }
    // Uncommon sits between the two: no tell, so the tell stays a rare
    // signal, but a stronger landing settle than a common draw gets.
    final peak = _rarity == Rarity.uncommon ? 0.75 : 0.55;
    final rest = _rarity == Rarity.uncommon ? 0.5 : 0.35;
    return _piecewise(
      t,
      const [0.0, 0.40, 0.66, 1.0],
      [0.0, 0.0, peak, rest],
    );
  }

  /// Blur radius, in the mockup's own units: rare 20 → 74 → 44 → 34,
  /// common 22 → 12. A common settle is a tenth of the rare bloom.
  double get glowBlur {
    final t = _controller.value;
    if (_isRare) {
      return _piecewise(
        t,
        const [0.0, 0.119, 0.66, 0.779, 1.0],
        const [20.0, 20.0, 74.0, 44.0, 34.0],
      );
    }
    final peak = _rarity == Rarity.uncommon ? 34.0 : 22.0;
    return _piecewise(
        t, const [0.0, 0.40, 0.66, 1.0], [peak, peak, peak, 12.0]);
  }

  /// Spread radius: rare 4 → 26 → 12 → 9, common 3 → 1.
  double get glowSpread {
    final t = _controller.value;
    if (_isRare) {
      return _piecewise(
        t,
        const [0.0, 0.119, 0.66, 0.779, 1.0],
        const [4.0, 4.0, 26.0, 12.0, 9.0],
      );
    }
    final peak = _rarity == Rarity.uncommon ? 5.0 : 3.0;
    return _piecewise(t, const [0.0, 0.40, 0.66, 1.0], [peak, peak, peak, 1.0]);
  }

  /// Brass for rare and uncommon; a common draw settles in the pale lavender
  /// the mockup uses, `rgba(185,174,230,…)`, which is [QuestPalette.dim].
  /// Brass is the rarity language everywhere else, so a common draw must not
  /// borrow it.
  Color get tellColour =>
      _rarity == Rarity.common ? QuestPalette.dim : QuestPalette.amber;

  /// Peak glow strength for this rarity, kept for callers that only need the
  /// ladder rather than the curve.
  double get tellStrength {
    switch (_rarity) {
      case Rarity.common:
        return 0.55;
      case Rarity.uncommon:
        return 0.75;
      case Rarity.rare:
        return 1.0;
    }
  }

  /// How far the card has lifted off the table, in design pixels before
  /// screen scaling. Zero back and landed; negative — risen — mid-flip.
  double get lift => _liftFor(flipProgress);

  /// Linear progress through the flip window, 0 at its start and 1 at its end.
  ///
  /// The lift, scale and ground shadow are keyed to THIS, not to [rotation].
  /// `rotation` is eased, so it rushes through its middle values: keying the
  /// peak to it both placed the peak after the card was edge-on and squashed
  /// it to roughly half amplitude. CSS keyframes are positions in time, and so
  /// are these.
  double get flipProgress {
    const start = CardRevealOrganism.tellEnd;
    const end = CardRevealOrganism.flipEnd;
    return ((_controller.value - start) / (end - start)).clamp(0.0, 1.0);
  }

  /// The card's own scale as it turns. It grows slightly through the flip.
  double get cardScale => _scaleFor(flipProgress);

  /// The ground shadow's scale: it contracts as the card lifts.
  double get groundScale => _groundScaleFor(flipProgress);

  /// The ground shadow's opacity, dimming as it contracts.
  double get groundOpacity => _groundOpacityFor(flipProgress);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: CardRevealOrganism.totalDuration,
    );
    // Built even when motion is off or the draw is common, so dispose never
    // reaches back into a deactivated element for a ticker it never started.
    _rayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );
    _flip = CurvedAnimation(
      parent: _controller,
      // Back 190ms, tell 450ms, then the flip, then the landing.
      curve: const Interval(
        CardRevealOrganism.tellEnd,
        CardRevealOrganism.flipEnd,
        curve: Curves.easeInOutCubic,
      ),
    );
    // The headline waits for the flip to finish. Riding the flip's own midpoint
    // would announce the result while the card was still edge-on, which reads
    // as the app spoiling its own reveal.
    _landing = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.66, 0.85, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Duration.zero still *arrives*, which is what keeps the card face up
    // rather than frozen face down when motion is off.
    _controller.duration = MotionPolicy.duration(
      context,
      CardRevealOrganism.totalDuration,
    );
    if (!_controller.isAnimating && !_controller.isCompleted) {
      _controller.forward();
    }

    if (_flourishWanted) {
      if (!_rayController.isAnimating) _rayController.repeat();
    } else if (_rayController.isAnimating) {
      _rayController.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _rayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outcome = widget.params.outcome;
    final showFlourish = _flourishWanted;
    // The tell runs at every rarity; only its strength and colour change.
    final showTell = MotionPolicy.idle(context);
    final cardW = _cardDesignWidth.w;
    final cardH = cardW / CollectibleCardAtom.aspectRatio;

    return GestureDetector(
      onTap: widget.params.onDismiss,
      behavior: HitTestBehavior.opaque,
      child: ColoredBox(
        color: QuestPalette.night.withValues(alpha: 0.92),
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_controller, _rayController]),
            builder: (context, _) {
              final t = _controller.value;
              final rot = rotation;
              final faceUp = rot >= 0.5;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // 4. Rays — a slow, continuous starburst, rare only.
                      if (showFlourish)
                        Positioned(
                          left: -0.7 * cardW,
                          right: -0.7 * cardW,
                          top: -0.7 * cardH,
                          bottom: -0.7 * cardH,
                          child: CustomPaint(
                            key: const ValueKey('reveal-rays'),
                            painter: _RaysPainter(
                              opacity: _rayOpacityFor(t),
                              turns: _rayController.value,
                            ),
                          ),
                        ),

                      // 1. Ground shadow — every rarity. Contracts as the
                      // card lifts, which is what sells the lift.
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: -10.h,
                        child: Center(
                          child: Opacity(
                            opacity: groundOpacity,
                            child: Transform.scale(
                              scale: groundScale,
                              child: Container(
                                key: const ValueKey('reveal-ground'),
                                width: cardW * 0.76,
                                height: 14.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999.r),
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.black.withValues(alpha: 0.7),
                                      Colors.black.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 3. Glow — builds in the tell, peaks on landing,
                      // settles. Scaled by [glowScaleX] so it foreshortens
                      // with the card.
                      //
                      // Every rarity, not just rare: its strength and colour
                      // come from [tellStrength] and [tellColour], which is
                      // what "the glow builds, strength scales with rarity"
                      // means. Gating it on rare made the ladder a switch and
                      // left a common draw with no tell at all.
                      if (showTell)
                        Positioned(
                          left: -9.w,
                          right: -9.w,
                          top: -9.h,
                          bottom: -9.h,
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..scale(CardRevealOrganism.glowScaleX(rot), 1.0),
                            child: Container(
                              key: const ValueKey('reveal-glow'),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: tellColour.withValues(
                                        alpha: 0.6 * glowOpacity),
                                    blurRadius: 70 * glowOpacity,
                                    spreadRadius: 22 * glowOpacity,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // 5. Rings — two, popping outward from the card edge.
                      // The second is delayed slightly behind the first.
                      if (showFlourish) _ring('reveal-ring-1', 0.0, t),
                      if (showFlourish) _ring('reveal-ring-2', 0.03, t),

                      // 6. Motes — four warm particles rising and fading,
                      // staggered, low on the card.
                      if (showFlourish)
                        _mote(
                            'reveal-mote-0', 0.18, 0.22, 0.00, cardW, cardH, t),
                      if (showFlourish)
                        _mote(
                            'reveal-mote-1', 0.74, 0.30, 0.03, cardW, cardH, t),
                      if (showFlourish)
                        _mote(
                            'reveal-mote-2', 0.40, 0.14, 0.06, cardW, cardH, t),
                      if (showFlourish)
                        _mote(
                            'reveal-mote-3', 0.62, 0.18, 0.09, cardW, cardH, t),

                      // 2 & 8. The card itself: lifts and grows as it turns,
                      // every rarity, then un-mirrors past edge-on so the art
                      // renders the right way round.
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0011)
                          ..rotateY(rot * math.pi)
                          ..translate(0.0, lift.h)
                          ..scale(cardScale),
                        child: faceUp
                            ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(math.pi),
                                child: _fan(
                                  outcome,
                                  overlay:
                                      showFlourish ? _sweepOverlay(t) : null,
                                ),
                              )
                            : const CardBackAtom(width: _cardDesignWidth),
                      ),
                    ],
                  ),
                  SizedBox(height: 18.h),
                  // 9. Headline — unchanged, on the landing.
                  Opacity(
                    opacity: _landing.value,
                    child: Text(
                      outcome.kind.headline,
                      style: TextStyle(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w800,
                        color: _headlineColour(outcome),
                      ),
                    ),
                  ),
                  // The mockup pairs every headline with a quiet line: the
                  // headline says what happened, this says what it means.
                  if (widget.params.supportingLine.isNotEmpty)
                    Opacity(
                      opacity: _landing.value,
                      child: Padding(
                        padding: EdgeInsets.only(top: 11.h),
                        child: Text(
                          widget.params.supportingLine,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            height: 1.45,
                            color: QuestPalette.muted,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Color _headlineColour(DrawOutcome outcome) {
    switch (outcome.kind) {
      case DrawResultKind.newCard:
        return QuestPalette.mint;
      case DrawResultKind.upgrade:
        return QuestPalette.amber;
      case DrawResultKind.duplicate:
        return QuestPalette.body;
    }
  }

  /// One card, or a fan when more than one is held. Angles widen with the
  /// count, so the fan grows in spread rather than only in depth.
  ///
  /// [overlay] — the sweep — is painted only over the front card, clipped to
  /// its own corners, never over the dimmed fan siblings behind it.
  Widget _fan(DrawOutcome outcome, {Widget? overlay}) {
    final count = CardRevealOrganism.fanCountFor(outcome.copiesAfter);
    const spreads = <int, List<double>>{
      1: [],
      2: [-8],
      3: [-13, 13],
      4: [-19, -7, 9],
    };

    final front = CollectibleCardAtom(
      card: outcome.card,
      width: 126,
      copies: outcome.copiesAfter,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        for (final angle in spreads[count]!)
          Transform.rotate(
            alignment: Alignment.bottomCenter,
            angle: angle * math.pi / 180,
            child: Opacity(
              opacity: 0.45,
              child: CollectibleCardAtom(
                card: outcome.card,
                width: 126,
                showScale: false,
                copies: 1,
              ),
            ),
          ),
        if (overlay == null)
          front
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: Stack(children: [front, overlay]),
          ),
      ],
    );
  }

  /// 5. One ring: hidden, then a quick pop, then it expands outward while
  /// fading. [delay] staggers the second ring behind the first.
  Widget _ring(String keyName, double delay, double t) {
    return Positioned.fill(
      child: Opacity(
        opacity: _ringOpacityFor(t, delay),
        child: Transform.scale(
          scale: _ringScaleFor(t, delay),
          child: Container(
            key: ValueKey(keyName),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: QuestPalette.amber.withValues(alpha: 0.9),
                width: 2.w,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 6. One mote: pops in low on the card, rises, and fades — staggered by
  /// [delay] within the landing.
  Widget _mote(
    String keyName,
    double leftFraction,
    double bottomFraction,
    double delay,
    double cardW,
    double cardH,
    double t,
  ) {
    return Positioned(
      left: cardW * leftFraction,
      bottom: cardH * bottomFraction,
      child: Opacity(
        opacity: _moteOpacityFor(t, delay),
        child: Transform.translate(
          offset: Offset(0, _moteLiftFor(t, delay).h),
          child: Transform.scale(
            scale: _moteScaleFor(t, delay),
            child: Container(
              key: ValueKey(keyName),
              width: 3.w,
              height: 3.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFE9B8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 7. Sweep — a specular shine crossing the face once it is up. Positioned
  /// to fill whatever it is clipped into by the caller.
  Widget _sweepOverlay(double t) {
    return Positioned.fill(
      child: Opacity(
        opacity: _sweepOpacityFor(t),
        child: FractionalTranslation(
          translation: Offset(_sweepXFor(t), 0),
          child: Container(
            key: const ValueKey('reveal-sweep'),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.34, 0.46, 0.50, 0.54, 0.66],
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.55),
                  const Color(0xFFFFF6DE).withValues(alpha: 0.8),
                  Colors.white.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- Shape functions --------------------------------------------------
  //
  // Every layer below is a pure function of either [rotation] (0 at back and
  // landed, 1 at face-up — "across the flip") or the controller's own [t]
  // (0 to 1 over the whole reveal — for anything keyed to the tell or the
  // landing, which live outside the flip's own span). None of them read
  // instance state, so they are easy to reason about and to test in
  // isolation from the widget tree.

  /// Piecewise-linear interpolation through a handful of keyframe stops —
  /// shared by every layer whose motion is a short list of stops rather than
  /// one smooth curve.
  static double _piecewise(double x, List<double> xs, List<double> ys) {
    if (x <= xs.first) return ys.first;
    if (x >= xs.last) return ys.last;
    for (var i = 0; i < xs.length - 1; i++) {
      if (x <= xs[i + 1]) {
        final span = xs[i + 1] - xs[i];
        final localT = span == 0 ? 0.0 : (x - xs[i]) / span;
        return ys[i] + (ys[i + 1] - ys[i]) * localT;
      }
    }
    return ys.last;
  }

  /// translateY 0 → -6 → -12 → -5 → 0, peaking at the 90° point.
  static double _liftFor(double t) => _piecewise(
        t,
        const [0.0, 0.214, 0.464, 0.714, 1.0],
        const [0.0, -6.0, -12.0, -5.0, 0.0],
      );

  /// scale 1.0 → 1.03 → 1.06 → 1.03 → 1.04 → 1.0, peaking at the 90° point.
  static double _scaleFor(double t) => _piecewise(
        t,
        const [0.0, 0.214, 0.464, 0.714, 1.0],
        const [1.0, 1.03, 1.06, 1.03, 1.0],
      );

  /// Ground shadow scale 1.0 → 0.62 → 0.94 → 1.0 across the flip.
  static double _groundScaleFor(double t) => _piecewise(
        t,
        const [0.0, 0.214, 0.464, 0.714, 1.0],
        const [1.0, 1.0, 0.62, 0.94, 1.0],
      );

  /// Ground shadow opacity 0.75 → 0.35 → 0.66 → 0.75 across the flip.
  static double _groundOpacityFor(double t) => _piecewise(
        t,
        const [0.0, 0.214, 0.464, 0.714, 1.0],
        const [0.75, 0.75, 0.35, 0.66, 0.75],
      );

  /// Rays: hidden until the landing, then fade in — with a small overshoot,
  /// as the CSS does — to about 0.42.
  static double _rayOpacityFor(double t) {
    if (t <= CardRevealOrganism.flipEnd) return 0.0;
    final p =
        ((t - CardRevealOrganism.flipEnd) / (1.0 - CardRevealOrganism.flipEnd))
            .clamp(0.0, 1.0);
    if (p <= 0.25) return 0.95 * Curves.easeOut.transform(p / 0.25);
    final settleT = ((p - 0.25) / 0.75).clamp(0.0, 1.0);
    return 0.95 + (0.42 - 0.95) * Curves.easeOut.transform(settleT);
  }

  static double _ringScaleFor(double t, double delay) {
    final start = CardRevealOrganism.flipEnd + delay;
    if (t <= start) return 1.0;
    final span = 1.0 - start;
    final p = span <= 0 ? 1.0 : ((t - start) / span).clamp(0.0, 1.0);
    if (p <= 0.12) return 1.0;
    final growT = ((p - 0.12) / 0.88).clamp(0.0, 1.0);
    return 1.0 + 0.55 * Curves.easeOut.transform(growT);
  }

  static double _ringOpacityFor(double t, double delay) {
    final start = CardRevealOrganism.flipEnd + delay;
    if (t <= start) return 0.0;
    final span = 1.0 - start;
    final p = span <= 0 ? 1.0 : ((t - start) / span).clamp(0.0, 1.0);
    if (p <= 0.12) return 0.95 * (p / 0.12);
    final fadeT = ((p - 0.12) / 0.88).clamp(0.0, 1.0);
    return 0.95 * (1 - Curves.easeIn.transform(fadeT));
  }

  static double _moteOpacityFor(double t, double delay) {
    final start = CardRevealOrganism.flipEnd + delay;
    if (t <= start) return 0.0;
    final span = 1.0 - start;
    final p = span <= 0 ? 1.0 : ((t - start) / span).clamp(0.0, 1.0);
    if (p <= 0.15) return Curves.easeOut.transform(p / 0.15);
    final fadeT = ((p - 0.15) / 0.85).clamp(0.0, 1.0);
    return 1.0 - Curves.easeIn.transform(fadeT);
  }

  static double _moteLiftFor(double t, double delay) {
    final start = CardRevealOrganism.flipEnd + delay;
    if (t <= start) return 0.0;
    final span = 1.0 - start;
    final p = span <= 0 ? 1.0 : ((t - start) / span).clamp(0.0, 1.0);
    if (p <= 0.15) return -6.0 * (p / 0.15);
    final riseT = ((p - 0.15) / 0.85).clamp(0.0, 1.0);
    return -6.0 + (-44.0 - -6.0) * Curves.easeOut.transform(riseT);
  }

  static double _moteScaleFor(double t, double delay) {
    final start = CardRevealOrganism.flipEnd + delay;
    if (t <= start) return 0.4;
    final span = 1.0 - start;
    final p = span <= 0 ? 1.0 : ((t - start) / span).clamp(0.0, 1.0);
    if (p <= 0.15) return 0.4 + 0.6 * (p / 0.15);
    final fadeT = ((p - 0.15) / 0.85).clamp(0.0, 1.0);
    return 1.0 - 0.5 * Curves.easeIn.transform(fadeT);
  }

  /// The sweep happens early in the landing, then stays hidden.
  static const double _sweepEnd = 0.78;

  static double _sweepOpacityFor(double t) {
    if (t <= CardRevealOrganism.flipEnd || t >= _sweepEnd) return 0.0;
    final p = (t - CardRevealOrganism.flipEnd) /
        (_sweepEnd - CardRevealOrganism.flipEnd);
    if (p <= 0.1) return Curves.easeOut.transform(p / 0.1);
    final fadeT = ((p - 0.1) / 0.9).clamp(0.0, 1.0);
    return 1.0 - Curves.easeIn.transform(fadeT);
  }

  static double _sweepXFor(double t) {
    final p = ((t - CardRevealOrganism.flipEnd) /
            (_sweepEnd - CardRevealOrganism.flipEnd))
        .clamp(0.0, 1.0);
    return -1.2 + 2.4 * p;
  }
}

/// The rays: a conic starburst behind the card, rotating slowly and
/// continuously, masked to a soft-edged ring so it fades before reaching its
/// own bounds.
///
/// A [CustomPainter] rather than a decorated [Container] — a `SweepGradient`
/// masked by a `RadialGradient` needs its own layer and blend mode, which a
/// [BoxDecoration] cannot express, and painting is cheaper than building a
/// subtree of gradient widgets every tick the rays spin.
class _RaysPainter extends CustomPainter {
  final double opacity;
  final double turns;

  const _RaysPainter({required this.opacity, required this.turns});

  // The seven bright wedges from the mockup's conic-gradient, as fractions of
  // a full turn, each paired with the alpha the mockup gives that wedge.
  static const List<double> _bandStarts = [
    0 / 360,
    30 / 360,
    62 / 360,
    128 / 360,
    187 / 360,
    250 / 360,
    330 / 360,
  ];
  static const List<double> _bandEnds = [
    7 / 360,
    35 / 360,
    69 / 360,
    135 / 360,
    194 / 360,
    257 / 360,
    337 / 360,
  ];
  static const List<double> _bandAlphas = [
    0.24,
    0.18,
    0.24,
    0.22,
    0.20,
    0.24,
    0.20,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || size.isEmpty) return;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final stops = <double>[];
    final colors = <Color>[];
    for (var i = 0; i < _bandStarts.length; i++) {
      final bright = QuestPalette.amber.withValues(
        alpha: _bandAlphas[i] * opacity,
      );
      stops
        ..add(_bandStarts[i])
        ..add(_bandEnds[i]);
      colors
        ..add(bright)
        ..add(bright);
      if (i < _bandStarts.length - 1) {
        stops
          ..add(_bandEnds[i])
          ..add(_bandStarts[i + 1]);
        colors
          ..add(Colors.transparent)
          ..add(Colors.transparent);
      }
    }
    stops
      ..add(_bandEnds.last)
      ..add(1.0);
    colors
      ..add(Colors.transparent)
      ..add(Colors.transparent);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(turns * 2 * math.pi);
    canvas.translate(-center.dx, -center.dy);

    canvas.saveLayer(rect, Paint());
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader =
            SweepGradient(colors: colors, stops: stops).createShader(rect),
    );
    // mask-image: radial-gradient(circle,#000 18%,transparent 62%) — opaque
    // near the card, fading to nothing by 62% of the radius.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = const RadialGradient(
          colors: [Colors.black, Colors.black, Colors.transparent],
          stops: [0.0, 0.18, 0.62],
        ).createShader(rect),
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RaysPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.turns != turns;
}
