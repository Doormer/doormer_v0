import 'dart:math' as math;

import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/core/theme/css_gradients.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/card_pop_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/level_icon_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/level_icons_atom.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../atoms/sparkle_atom.dart';
import '../atoms/sunburst_atom.dart';
import '../params/new_level_pop_up_params.dart';

/// Opens the pop-up for a new level over the whole screen, nav bar
/// included. Nice!, the back gesture, Escape and a tap outside it close it.
/// On the web, the browser's back button moves the app's router instead,
/// so it changes the page under the pop-up and leaves it open, as it does
/// for every dialog in the app.
Future<void> showNewLevelPopUp(
  BuildContext context,
  NewLevelPopUpParams params,
) {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierColor: NewLevelPopUpOrganism.scrimColor,
    builder: (dialogContext) => NewLevelPopUpOrganism(
      params: params,
      onClose: () => Navigator.of(dialogContext).pop(),
    ),
  );
}

/// The moment a count of the day raises the student's level: a card with
/// the new icon over a golden sunburst, "New moon!", "You're level 4." and
/// Nice!.
///
/// It moves as the QQ Gold mockup does, in about two seconds. The card
/// rises in. For a moon or a sun, four smaller icons pop in and fly
/// together, a flash follows and the new icon pops in; a star pops in
/// straight away. The words rise one after another. Then, until it closes,
/// the sunburst turns, the halo breathes, the icon bobs and six sparkles
/// twinkle. With motion off it is the finished card, still.
class NewLevelPopUpOrganism extends StatefulWidget {
  /// The widest the card grows, in design pixels.
  static const double maxWidth = 322;

  /// The dimmed screen around it: [QuestPalette.night] at 74%, standing in
  /// for the mockup's `rgba(5, 3, 14, .74)`.
  static final Color scrimColor = QuestPalette.night.withValues(alpha: 0.74);

  final NewLevelPopUpParams params;

  /// Nice!: closes it.
  final VoidCallback onClose;

  const NewLevelPopUpOrganism({
    super.key,
    required this.params,
    required this.onClose,
  });

  @override
  State<NewLevelPopUpOrganism> createState() => _NewLevelPopUpOrganismState();
}

class _NewLevelPopUpOrganismState extends State<NewLevelPopUpOrganism>
    with SingleTickerProviderStateMixin {
  /// The seconds since the pop-up opened, for as long as it is open. Every
  /// part is read from this one clock, as the mockup's CSS reads every
  /// animation from the page's one timeline.
  late final AnimationController _clock;

  @override
  void initState() {
    super.initState();
    // Made even when motion is off, so dispose never reaches back for a
    // ticker it never started.
    _clock = AnimationController.unbounded(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MotionPolicy.of(context)) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.animateWith(_Clock(from: _clock.value));
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = widget.params;
    final merges = params.smallerIcon != null;
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: params.announcement,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 19.w),
          // On a short screen, such as a phone turned sideways, the card
          // scrolls rather than cutting Nice! off. When it fits, the scroll
          // view is only as big as the card, so a tap beside it still
          // reaches the scrim. Clip.none keeps the card's shadow.
          child: SingleChildScrollView(
            clipBehavior: Clip.none,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: NewLevelPopUpOrganism.maxWidth.w,
              ),
              child: AnimatedBuilder(
                animation: _clock,
                builder: (context, _) => _card(
                  MotionPolicy.of(context)
                      ? _Moment(_clock.value, merges: merges)
                      : _Moment.still(merges: merges),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(_Moment moment) {
    final params = widget.params;
    final smallerIcon = params.smallerIcon;
    final words = [
      Text(
        params.title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: kDisplayFont,
          fontSize: 28.sp,
          fontWeight: FontWeight.w700,
          color: QuestPalette.levelCream,
        ),
      ),
      Padding(
        padding: EdgeInsets.only(top: 6.h),
        child: Text(
          params.levelLine,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kBodyFont,
            fontSize: 14.sp,
            color: QuestPalette.body,
          ),
        ),
      ),
      if (smallerIcon != null)
        Padding(
          padding: EdgeInsets.only(top: 14.h, bottom: 2.h),
          child: _recap(smallerIcon),
        ),
      Padding(
        padding: EdgeInsets.only(top: 16.h),
        child: _niceButton(),
      ),
    ];
    return Opacity(
      opacity: moment.cardOpacity,
      child: Transform.translate(
        offset: Offset(0, moment.cardDrop.h),
        child: Transform.scale(
          scale: moment.cardScale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26.r),
              border: Border.all(
                color: QuestPalette.levelGold.withValues(alpha: 0.3),
              ),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                // The mockup's `linear-gradient(170deg, …)`.
                transform: CssAngle(170),
                colors: [
                  QuestPalette.levelPopUpTop,
                  QuestPalette.levelCardMiddle,
                ],
                stops: [0, 0.7],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  offset: Offset(0, 30.h),
                  blurRadius: 80.r,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26.r),
              child: Material(
                type: MaterialType.transparency,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(22.w, 20.h, 22.w, 22.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Only the picture moves once the card has risen, so
                      // it repaints on its own, without the card's shadow.
                      SizedBox(
                        height: 190.h,
                        child: RepaintBoundary(child: _picture(moment)),
                      ),
                      for (final (order, word) in words.indexed)
                        _rising(moment.word(order), word),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The new icon over its sunburst and halo, with the flash, the merging
  /// smaller icons and the sparkles.
  Widget _picture(_Moment moment) {
    final params = widget.params;
    final smallerIcon = params.smallerIcon;
    final halo = moment.halo;
    final flash = moment.flash;
    return LayoutBuilder(
      builder: (context, box) => Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: moment.raysOpacity,
            child: OverflowBox(
              maxWidth: 300.w,
              maxHeight: 300.w,
              child: SunburstAtom(size: 300.w, turns: moment.raysTurns),
            ),
          ),
          Opacity(
            opacity: halo.opacity,
            child: Transform.scale(
              scale: halo.scale,
              child: _glow(
                const ValueKey('new-level-halo'),
                size: 170.w,
                colors: [
                  QuestPalette.levelHalo.withValues(alpha: 0.55),
                  QuestPalette.levelHalo.withValues(alpha: 0.1),
                  QuestPalette.levelHalo.withValues(alpha: 0),
                ],
                stops: const [0, 0.68, 1],
              ),
            ),
          ),
          Opacity(
            opacity: flash.opacity,
            child: Transform.scale(
              scale: flash.scale,
              child: _glow(
                const ValueKey('new-level-flash'),
                size: 120.w,
                colors: [
                  QuestPalette.levelCream,
                  QuestPalette.levelPaleGold.withValues(alpha: 0.6),
                  QuestPalette.levelPaleGold.withValues(alpha: 0),
                ],
                stops: const [0, 0.45, 0.72],
              ),
            ),
          ),
          if (smallerIcon != null)
            for (var index = 0; index < 4; index++)
              _smallerIcon(moment.smallerIcon(index), index, smallerIcon),
          Opacity(
            opacity: moment.iconOpacity,
            child: Transform.translate(
              offset: Offset(0, -moment.iconLift.h),
              child: Transform.scale(
                scale: moment.iconScale,
                child: RepaintBoundary(
                  child: LevelIconAtom(
                    key: const ValueKey('new-level-icon'),
                    icon: params.newIcon,
                    size: 100.w,
                  ),
                ),
              ),
            ),
          ),
          for (final (index, spot) in _Moment.sparkleSpots.indexed)
            Positioned(
              left: spot.dx * box.maxWidth,
              top: spot.dy * box.maxHeight,
              child: Opacity(
                opacity: moment.sparkle(index).opacity,
                child: Transform.scale(
                  scale: moment.sparkle(index).scale,
                  child: RepaintBoundary(
                    child: SparkleAtom(
                      key: ValueKey('sparkle-$index'),
                      size: 16.w,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _smallerIcon(
    ({double x, double scale, double opacity}) at,
    int index,
    LevelIcon icon,
  ) {
    return Opacity(
      opacity: at.opacity,
      child: Transform.translate(
        offset: Offset(at.x.w, 0),
        child: Transform.scale(
          scale: at.scale,
          child: RepaintBoundary(
            child: LevelIconAtom(
              key: ValueKey('smaller-icon-$index'),
              icon: icon,
              size: 30.w,
            ),
          ),
        ),
      ),
    );
  }

  /// A soft round glow [size] across, through [colors] from the middle out.
  static Widget _glow(
    Key key, {
    required double size,
    required List<Color> colors,
    required List<double> stops,
  }) {
    return SizedBox.square(
      key: key,
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors, stops: stops),
        ),
      ),
    );
  }

  /// Four smaller icons, an arrow and the new icon: what made the new level.
  /// The words say it already, so screen readers skip it.
  Widget _recap(LevelIcon smallerIcon) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: Row(
          key: const ValueKey('new-level-recap'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LevelIconsAtom(
              suns: 0,
              moons: smallerIcon == LevelIcon.moon ? 4 : 0,
              stars: smallerIcon == LevelIcon.star ? 4 : 0,
              size: 20.w,
              semanticLabel: null,
            ),
            SizedBox(width: 10.w),
            Icon(
              Icons.arrow_forward_rounded,
              size: 20.w,
              color: QuestPalette.dim,
            ),
            SizedBox(width: 10.w),
            LevelIconAtom(icon: widget.params.newIcon, size: 26.w),
          ],
        ),
      ),
    );
  }

  Widget _niceButton() {
    final corners = BorderRadius.circular(22.r);
    return TextButton(
      autofocus: true,
      onPressed: widget.onClose,
      style: TextButton.styleFrom(
        foregroundColor: QuestPalette.onLevelGold,
        minimumSize: Size.fromHeight(44.h),
        // 44 on computers too, where the default compact density would
        // take 8 off.
        visualDensity: VisualDensity.standard,
        shape: RoundedRectangleBorder(borderRadius: corners),
        textStyle: TextStyle(
          fontFamily: kDisplayFont,
          fontSize: 17.sp,
          fontWeight: FontWeight.w700,
        ),
        // The gold is inked inside the button's own shape, under its press
        // highlight. A phone's bigger tap area around it stays clear.
        backgroundBuilder: (context, states, child) => Ink(
          key: const ValueKey('nice-gold'),
          decoration: BoxDecoration(
            borderRadius: corners,
            gradient: const LinearGradient(
              colors: [QuestPalette.levelButton, QuestPalette.levelGold],
            ),
          ),
          child: child,
        ),
      ),
      child: const Text('Nice!'),
    );
  }

  /// [word], rising into place as [rise] says. Screen readers have it from
  /// the start, while it is still faded out.
  static Widget _rising(({double opacity, double drop}) rise, Widget word) {
    return Opacity(
      opacity: rise.opacity,
      alwaysIncludeSemantics: true,
      child: Transform.translate(offset: Offset(0, rise.drop.h), child: word),
    );
  }
}

/// Time, in seconds from [from]: as an [AnimationController]'s simulation,
/// it makes the controller's value the seconds since the pop-up opened, for
/// as long as it runs.
class _Clock extends Simulation {
  final double from;

  _Clock({required this.from});

  @override
  double x(double time) => from + time;

  @override
  double dx(double time) => 1;

  @override
  bool isDone(double time) => false;
}

/// Every part of the pop-up [seconds] after it opened: the mockup's keyframes
/// and timings (`animate.py`), read at one moment. [_Moment.still] is the
/// finished card, for when motion is off.
class _Moment {
  /// Seconds since the pop-up opened.
  final double seconds;

  /// Whether four smaller icons merge into the new one first, as for a moon
  /// or a sun. A star pops in straight away.
  final bool merges;

  /// Whether motion is off: every part where the motion leaves it, still.
  final bool isStill;

  const _Moment(this.seconds, {required this.merges}) : isStill = false;

  const _Moment.still({required this.merges})
      : seconds = 0,
        isStill = true;

  /// Where the four smaller icons first sit, across from the middle, in
  /// design pixels.
  static const List<double> smallerIconXs = [-84, -28, 28, 84];

  /// Where the six sparkles sit, as shares of the picture's width and
  /// height.
  static const List<Offset> sparkleSpots = [
    Offset(.22, .18),
    Offset(.76, .14),
    Offset(.84, .62),
    Offset(.14, .66),
    Offset(.60, .86),
    Offset(.34, .82),
  ];

  /// When each sparkle starts to twinkle, in seconds after the flash.
  static const List<double> _sparkleStarts = [.3, .8, .5, 1.1, 1.4, .6];

  // The mockup's own curves. CSS's ease-out and ease-in-out are
  // Curves.easeOut and Curves.easeInOut.
  static const Curve _rise = Cubic(.2, .8, .2, 1);
  static const Curve _popIn = Cubic(.2, 1.4, .4, 1);
  static const Curve _merge = Cubic(.55, 0, .85, .35);

  /// When the flash comes, with the new icon popping in just after it: a
  /// moon or a sun waits for its smaller icons to merge, and a star comes
  /// as the card finishes rising.
  double get _reveal => merges ? 1.1 : 0.2;

  /// How far [seconds] is through a stretch of [length] from [start], from
  /// 0 to 1.
  double _through(double start, double length) =>
      ((seconds - start) / length).clamp(0.0, 1.0);

  /// How far [seconds] is through the current round of a loop of [period]
  /// that began at [start], from 0 to 1, or null before it began.
  double? _round(double start, double period) =>
      seconds < start ? null : ((seconds - start) / period) % 1;

  /// From [from] to [to] and back over a round of a loop, easing each way,
  /// as the mockup's `0%, 100%` and `50%` keyframes do.
  static double _thereAndBack(double round, double from, double to) {
    final way = round < .5 ? round * 2 : (1 - round) * 2;
    return from + (to - from) * Curves.easeInOut.transform(way);
  }

  /// The card rising in, from 0 to 1.
  double get _cardIn => isStill ? 1 : _rise.transform(_through(0, .34));

  double get cardOpacity => _cardIn;

  /// How far below its place the card still is, in design pixels.
  double get cardDrop => 28 * (1 - _cardIn);

  double get cardScale => 1 - .03 * (1 - _cardIn);

  /// The smaller icon at [index]: popping in one after another from
  /// 0.22 s, then flying to the middle, shrinking and fading from 0.7 s to
  /// 1.15 s.
  ({double x, double scale, double opacity}) smallerIcon(int index) {
    if (isStill) return (x: 0, scale: .35, opacity: 0);
    final grown = _popIn.transform(_through(.22 + .06 * index, .28));
    final merged = _merge.transform(_through(.7, .45));
    return (
      x: smallerIconXs[index] * (1 - merged),
      scale: (.2 + .8 * grown) * (1 - .65 * merged),
      opacity: grown.clamp(0.0, 1.0) * (1 - merged),
    );
  }

  /// The flash: bright fast, then growing as it fades.
  ({double scale, double opacity}) get flash {
    if (isStill) return (scale: 1.9, opacity: 0);
    final through = _through(_reveal, .55);
    return (
      scale: .3 + 1.6 * Curves.easeOut.transform(through),
      opacity: through <= .3
          ? Curves.easeOut.transform(through / .3)
          : 1 - Curves.easeOut.transform((through - .3) / .7),
    );
  }

  /// Hidden until the new icon pops in, just after the flash.
  double get iconOpacity => isStill || seconds >= _reveal + .02 ? 1 : 0;

  /// The new icon popping in, with the card reveal's 480 ms overshoot.
  double get iconScale {
    if (isStill) return 1;
    final pop =
        CardPopAtom.duration.inMicroseconds / Duration.microsecondsPerSecond;
    return .2 +
        .8 * CardPopAtom.overshoot.transform(_through(_reveal + .02, pop));
  }

  /// How far the new icon has bobbed up, in design pixels: 3 at the top of
  /// each 3.2 s round.
  double get iconLift {
    final round = isStill ? null : _round(_reveal + .7, 3.2);
    return round == null ? 0 : _thereAndBack(round, 0, 3);
  }

  double get raysOpacity =>
      isStill ? 1 : Curves.easeOut.transform(_through(_reveal + .05, .5));

  /// How far the sunburst has turned: once every 18 s.
  double get raysTurns =>
      isStill ? 0 : math.max(0.0, seconds - _reveal - .05) / 18;

  /// The halo fading in, then breathing every 2.6 s.
  ({double scale, double opacity}) get halo {
    if (isStill) return (scale: 1, opacity: 1);
    final round = _round(_reveal + .5, 2.6);
    if (round == null) {
      return (
        scale: 1,
        opacity: Curves.easeOut.transform(_through(_reveal + .05, .4)),
      );
    }
    return (
      scale: _thereAndBack(round, 1, 1.08),
      opacity: _thereAndBack(round, 1, .8),
    );
  }

  /// The sparkle at [index], twinkling every 1.8 s from its own start.
  ({double scale, double opacity}) sparkle(int index) {
    if (isStill) return (scale: 1, opacity: 1);
    final round = _round(_reveal + _sparkleStarts[index], 1.8);
    if (round == null) return (scale: .4, opacity: 0);
    return (
      scale: _thereAndBack(round, .4, 1),
      opacity: _thereAndBack(round, 0, 1),
    );
  }

  /// The word at [order], rising in after the one before it.
  ({double opacity, double drop}) word(int order) {
    if (isStill) return (opacity: 1, drop: 0);
    final risen = Curves.easeOut.transform(
      _through(_reveal + .25 + .15 * order, .35),
    );
    return (opacity: risen, drop: 8 * (1 - risen));
  }
}
