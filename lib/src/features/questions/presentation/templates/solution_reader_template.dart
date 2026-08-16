import 'dart:async';

import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/atoms/xp_pellet_atom.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_reader_presenter.dart';
import 'package:doormer/src/features/questions/presentation/molecules/solution_trail_molecule.dart';
import 'package:doormer/src/features/questions/presentation/molecules/swipe_hint_molecule.dart';
import 'package:doormer/src/features/questions/presentation/organisms/quest_hud_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_briefing_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_step_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_vault_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/quest_hud_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_briefing_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_reader_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_step_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/quest_backdrop.dart';
import 'package:doormer/src/shared/design/atomic/atoms/card_pop_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Owns the page's single Scaffold.
///
/// Every step card overflows the viewport (750/552/552px measured against a
/// 468px scroll region), so the trail and the CTA pin and only the body
/// scrolls: progress and the destination stay in sight while the student reads
/// a step taller than the screen.
///
/// Because one scroll view serves every screen, moving to a new screen must
/// reset its offset. Without that the offset carries over and the student
/// lands mid-screen with the heading scrolled off above them — measured at
/// 253px into step one after reading a briefing, and 164px into step two after
/// reading step one. A disclosure toggle is not a new screen and holds place.
class SolutionReaderTemplate extends StatefulWidget {
  final SolutionReaderParams params;

  const SolutionReaderTemplate({super.key, required this.params});

  @override
  State<SolutionReaderTemplate> createState() => _SolutionReaderTemplateState();
}

class _SolutionReaderTemplateState extends State<SolutionReaderTemplate>
    with SingleTickerProviderStateMixin {
  /// Headroom inside the scroll view for the XP sticker, which is positioned
  /// 9px above the card's top edge and so sits outside it. With a zero top
  /// padding the viewport clipped the sticker in half — the tag read as a torn
  /// mint strip rather than a reward.
  static const double _stickerHeadroom = 14;

  /// Below this a sideways drag is browsing, not a decision.
  static const double _swipeVelocity = 320;

  final ScrollController _scrollController = ScrollController();

  /// Locates the vault so revealing the answer can bring it into view.
  /// The lock resists before it gives. Revealing on the press makes the answer
  /// feel handed over; a moment of refusal makes it feel taken. It lives here,
  /// not in the vault, so the whole page turns over on the same beat — the
  /// working, the button and the answer all belong to one moment.
  static const Duration _resistFor = Duration(milliseconds: 450);

  Timer? _resistTimer;
  bool _resisting = false;

  final GlobalKey _vaultKey = GlobalKey();

  /// The pellet's two ends, and the box it flies across.
  final GlobalKey _stickerKey = GlobalKey();
  final GlobalKey _chipKey = GlobalKey();
  final GlobalKey _stageKey = GlobalKey();

  /// 190ms of nothing, then 640ms of flight. The wait lets the new card finish
  /// arriving — a pellet launched into a card still popping in reads as part of
  /// the card rather than as a reward leaving it.
  static const double _flightLead = 190 / 830;

  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 830),
  );

  /// What the counter is *showing*, which lags the truth while a pellet is on
  /// its way. Held as the presenter's own pair so this never formats copy.
  String _bankedXpLabel = '';
  int _bankedXp = 0;

  /// The pellet in flight: what it carries and where it is going. Null between
  /// flights.
  int? _pelletAmount;
  Offset _pelletFrom = Offset.zero;
  Offset _pelletTo = Offset.zero;

  /// What a pellet in flight is going to bank when it lands. Held apart from
  /// the live content so a flight that is overtaken still commits the number it
  /// set out with.
  String? _pendingXpLabel;
  int? _pendingXp;

  /// Bumped every time XP lands, to punch the counter.
  int _landings = 0;

  /// Identifies which screen is showing. The level label already encodes the
  /// step, so this changes on exactly the transitions that should start at the
  /// top, and not on a rationale or answer toggle.
  String get _screenId {
    final content = widget.params.content;
    return content.onBriefing ? 'briefing' : content.levelLabel;
  }

  @override
  void initState() {
    super.initState();
    // Arriving with a standing already earned is not an award. Whatever the
    // first frame says is simply what the student walked in carrying.
    _bankedXpLabel = widget.params.content.xpLabel;
    _bankedXp = widget.params.content.xpTotal;
    _flight.addStatusListener((status) {
      if (status == AnimationStatus.completed) _landXp();
    });
  }

  /// Commits the number. This is the guaranteed path: every route that starts a
  /// pellet ends here, including the one where no pellet ever flew.
  ///
  /// Never keep the total inside the animation. The pellet is decoration — it
  /// does not run under reduced motion, and another award can cut it short —
  /// but the counter must arrive at the truth either way.
  void _landXp() {
    if (!mounted) return;
    _flight.stop();
    final label = _pendingXpLabel ?? widget.params.content.xpLabel;
    final total = _pendingXp ?? widget.params.content.xpTotal;
    setState(() {
      _pelletAmount = null;
      _pendingXpLabel = null;
      _pendingXp = null;
      _bankedXpLabel = label;
      _bankedXp = total;
      _landings++;
    });
  }

  /// Sends what a step just banked from its sticker to the counter.
  ///
  /// The pellet carries the difference actually banked, not the sticker's own
  /// text: the sticker shows the reward for the step now on screen, which is
  /// the next one. Reading it would send "+15" while the counter climbed 10.
  void _awardXp() {
    // A second award mid-flight commits the first. Skipping ahead may cost the
    // student the animation, but it must never cost them the XP.
    if (_pendingXp != null) _landXp();

    final content = widget.params.content;
    final delta = content.xpTotal - _bankedXp;

    if (delta <= 0 || !MotionPolicy.of(context)) {
      _pendingXpLabel = content.xpLabel;
      _pendingXp = content.xpTotal;
      _landXp();
      return;
    }

    final stage = _stageKey.currentContext?.findRenderObject();
    final sticker = _stickerKey.currentContext?.findRenderObject();
    final chip = _chipKey.currentContext?.findRenderObject();
    _pendingXpLabel = content.xpLabel;
    _pendingXp = content.xpTotal;

    if (stage is! RenderBox ||
        sticker is! RenderBox ||
        chip is! RenderBox ||
        !stage.hasSize ||
        !sticker.hasSize ||
        !chip.hasSize) {
      _landXp();
      return;
    }

    Offset centreIn(RenderBox box) =>
        stage.globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));

    setState(() {
      _pelletAmount = delta;
      _pelletFrom = centreIn(sticker);
      _pelletTo = centreIn(chip);
    });
    _flight.forward(from: 0);
  }

  @override
  void didUpdateWidget(SolutionReaderTemplate oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.params.content;
    final previousId = previous.onBriefing ? 'briefing' : previous.levelLabel;
    final movedOn = previousId != _screenId;
    if (movedOn) {
      // Geometry is only true once the new step has laid out.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _awardXp();
      });
    }
    if (movedOn && _scrollController.hasClients) {
      _scrollController.jumpTo(0);
      return;
    }

    // The answer is the payoff of the whole page, and it sits below the fold:
    // revealing it changed only the trail marker and the button, so the tap
    // read as having done nothing. Bring the vault to the student instead.
    final revealedNow =
        !previous.answerRevealed && widget.params.content.answerRevealed;
    if (revealedNow) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showVault());
    }
  }

  void _showVault() {
    final vaultContext = _vaultKey.currentContext;
    if (!mounted || vaultContext == null) return;
    Scrollable.ensureVisible(
      vaultContext,
      alignment: 0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  /// A decisive flick sideways moves between steps, the way the hint says it
  /// does. A slow drag is ignored: only a deliberate throw counts.
  void _swipe(DragEndDetails details, SolutionReaderContent content) {
    final v = details.primaryVelocity ?? 0;
    if (v.abs() < _swipeVelocity) return;
    if (v < 0) {
      if (!content.ctaEnabled) return;
      content.isLastStep ? _requestReveal() : widget.params.onNext();
    } else {
      if (!content.canGoBack) return;
      widget.params.onBack();
    }
  }

  void _requestReveal() {
    if (_resisting || widget.params.content.answerRevealed) return;
    if (!MotionPolicy.of(context)) {
      widget.params.onRevealAnswer();
      return;
    }
    setState(() => _resisting = true);
    _resistTimer = Timer(_resistFor, () {
      if (!mounted) return;
      setState(() => _resisting = false);
      widget.params.onRevealAnswer();
    });
  }

  @override
  void dispose() {
    _resistTimer?.cancel();
    _flight.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = widget.params;
    final content = params.content;

    return Scaffold(
      backgroundColor: QuestPalette.night,
      body: QuestBackdrop(
        child: Stack(
          key: _stageKey,
          children: [
            SafeArea(
              child: Column(
                children: [
                  QuestHudOrganism(
                    params: QuestHudParams(
                      topic: content.topic,
                      questionTitle: content.questionTitle,
                      // The banked total, not the live one: while a pellet is in
                      // flight the counter has not been paid yet, and a number that
                      // updates before the reward arrives makes the flight a lie.
                      xpLabel: _bankedXpLabel,
                      streakLabel: content.streakLabel,
                      streakAtStake: content.streakAtStake,
                      xpKey: _chipKey,
                      xpTrigger: _landings,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 2.h, 16.w, 0),
                    child: SolutionTrailMolecule(
                      nodes: content.trail,
                      onNodeTap: widget.params.onTravelTo,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      // Horizontal only: reading up and down must never cost
                      // the student their place.
                      onHorizontalDragEnd: (d) => _swipe(d, content),
                      child: SingleChildScrollView(
                        key: const Key('solution_scroll'),
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(
                          16.w,
                          _stickerHeadroom.h,
                          16.w,
                          16.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: content.onBriefing
                              ? [
                                  // Keyed by screen so the card pops and its contents
                                  // rise again on every move, rather than the words
                                  // silently changing inside a frame that never moved.
                                  CardPopAtom(
                                    key: ValueKey<String>(_screenId),
                                    child: SolutionBriefingOrganism(
                                      params: SolutionBriefingParams(
                                        title: content.briefingTitle,
                                        body: content.briefingBody,
                                        note: content.note,
                                        onEnlargeVisual: params.onEnlargeVisual,
                                        imageProviderBuilder:
                                            params.imageProviderBuilder,
                                      ),
                                    ),
                                  ),
                                ]
                              : [
                                  CardPopAtom(
                                    key: ValueKey<String>(_screenId),
                                    child: SolutionStepOrganism(
                                      params: SolutionStepParams(
                                        levelLabel: content.levelLabel,
                                        stepTitle: content.stepTitle,
                                        body: content.body,
                                        rationale: content.rationale,
                                        hasRationale: content.hasRationale,
                                        rationaleVisible:
                                            content.rationaleVisible,
                                        rationaleToggleLabel:
                                            content.rationaleToggleLabel,
                                        xpLabel: content.stepXpLabel,
                                        xpStickerKey: _stickerKey,
                                        onToggleRationale:
                                            params.onToggleRationale,
                                        onEnlargeVisual: params.onEnlargeVisual,
                                        imageProviderBuilder:
                                            params.imageProviderBuilder,
                                      ),
                                    ),
                                  ),
                                  SolutionVaultOrganism(
                                    key: _vaultKey,
                                    revealed: content.answerRevealed,
                                    unlockable: content.isLastStep,
                                    lockedLabel: content.vaultLockedLabel,
                                    solvedLabel: content.vaultSolvedLabel,
                                    checkTitle: content.checkTitle,
                                    checkBody: content.checkBody,
                                    answerBody: content.answerBody,
                                    resisting: _resisting,
                                    onReveal: _requestReveal,
                                    onEnlargeVisual: params.onEnlargeVisual,
                                    imageProviderBuilder:
                                        params.imageProviderBuilder,
                                  ),
                                ],
                        ),
                      ),
                    ),
                  ),
                  _CtaBar(params: params, onRequestReveal: _requestReveal),
                ],
              ),
            ),
            if (_pelletAmount != null) _buildPellet(),
          ],
        ),
      ),
    );
  }

  /// The pellet's arc: out past the midpoint, rising, then shrinking into the
  /// counter. A straight fade would say the XP evaporated; the arc says it was
  /// carried somewhere and put away.
  Widget _buildPellet() {
    return AnimatedBuilder(
      animation: _flight,
      builder: (context, child) {
        final t =
            ((_flight.value - _flightLead) / (1 - _flightLead)).clamp(0.0, 1.0);
        if (t == 0 || t >= 1) return const SizedBox.shrink();

        final e = const Cubic(.5, -0.2, .4, 1).transform(t);
        final d = _pelletTo - _pelletFrom;
        // Two legs, matching the keyframe at 60%: most of the distance is
        // covered while the pellet is still full size, then it drops into the
        // pill.
        final Offset at;
        final double scale;
        final double opacity;
        if (e <= 0.6) {
          final k = e / 0.6;
          at = Offset(d.dx * 0.55 * k, d.dy * 0.55 * k - 16 * k);
          scale = 1 - 0.14 * k;
          opacity = 1;
        } else {
          final k = (e - 0.6) / 0.4;
          at = Offset.lerp(
            Offset(d.dx * 0.55, d.dy * 0.55 - 16),
            d,
            k,
          )!;
          scale = 0.86 - 0.52 * k;
          opacity = 1 - k;
        }

        return Positioned(
          left: _pelletFrom.dx + at.dx,
          top: _pelletFrom.dy + at.dy,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(scale: scale, child: child),
            ),
          ),
        );
      },
      child: IgnorePointer(
        key: const Key('xp_pellet'),
        child: XpPelletAtom(amount: _pelletAmount ?? 0),
      ),
    );
  }
}

/// Opaque, with a 26px fade above it. At 92% opacity content showed through
/// and text was cut mid-glyph at the boundary, which reads as broken rather
/// than scrollable.
///
/// The primary button carries a hard 3px bottom edge rather than a blur. A
/// blurred drop shadow reads as a floating card; a solid edge reads as a key
/// you can press, which is the whole point of the last control on the page.
class _CtaBar extends StatelessWidget {
  final SolutionReaderParams params;

  /// Reveal goes through the page rather than straight to the bloc, so the
  /// lock gets its moment of refusal first.
  final VoidCallback onRequestReveal;

  const _CtaBar({required this.params, required this.onRequestReveal});

  @override
  Widget build(BuildContext context) {
    final content = params.content;
    final solved = !content.ctaEnabled;
    final accent = solved ? QuestPalette.mint : QuestPalette.violet;
    final edge = solved ? const Color(0xFF00A874) : const Color(0xFF4A2FD1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwipeHintMolecule(used: content.hasMoved),
        IgnorePointer(
          child: Container(
            height: 26.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  QuestPalette.glowBottom.withValues(alpha: 0),
                  QuestPalette.glowBottom,
                ],
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: QuestPalette.glowBottom,
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          padding: EdgeInsets.fromLTRB(13.w, 11.h, 13.w, 13.h),
          child: Row(
            children: [
              _GhostButton(
                enabled: content.canGoBack,
                onPressed: params.onBack,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _PrimaryCta(
                  label: content.ctaLabel,
                  accent: accent,
                  edge: edge,
                  onPressed: content.ctaEnabled
                      ? (content.isLastStep ? onRequestReveal : params.onNext)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GhostButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _GhostButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.34,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          key: const Key('solution_back'),
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            height: 48.h,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.24),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chevron_left_rounded,
                    size: 17.sp, color: QuestPalette.dim),
                Text(
                  'Back',
                  style: TextStyle(
                    fontFamily: kDisplayFont,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: QuestPalette.dim,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  final String label;
  final Color accent;
  final Color edge;
  final VoidCallback? onPressed;

  const _PrimaryCta({
    required this.label,
    required this.accent,
    required this.edge,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('solution_cta'),
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            height: 48.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(color: edge, offset: const Offset(0, 3)),
                BoxShadow(
                  color: accent.withValues(alpha: 0.42),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: kDisplayFont,
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: accent == QuestPalette.mint
                    ? QuestPalette.onMint
                    : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
