import 'dart:async';

import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/features/questions/presentation/atoms/quark_reward_atom.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_reader_presenter.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_trail_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/quest_hud_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_briefing_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_cta_bar_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_step_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_vault_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/quest_hud_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_briefing_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_cta_bar_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_reader_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_step_params.dart';
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

  /// Where the reward lands, and the box it flies across. It leaves from the
  /// vault.
  final GlobalKey _quarkDotKey = GlobalKey();
  final GlobalKey _stageKey = GlobalKey();

  /// 190ms of nothing, then 640ms of flight. The wait lets the vault finish
  /// opening — a reward launched from a vault still popping in reads as part of
  /// the vault rather than as a reward leaving it.
  static const double _flightLead = 190 / 830;

  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 830),
  );

  /// What the HUD balance is *showing*, which lags the truth while a reward is
  /// on its way. Held as the presenter's own label so this never formats copy.
  String _shownQuarkBalanceLabel = '';

  /// The reward in flight: what it reads and where it is going. Null between
  /// flights.
  String? _flyingRewardLabel;
  Offset _pelletFrom = Offset.zero;
  Offset _pelletTo = Offset.zero;

  /// What a reward in flight is going to show when it lands. Held apart from
  /// the live content so a flight that is overtaken still commits the balance
  /// it set out with.
  String? _pendingQuarkBalanceLabel;

  /// Bumped every time quarks land, to punch the balance.
  int _quarkLandings = 0;

  /// Identifies which screen is showing. The level label already encodes the
  /// step, so this changes on exactly the transitions that should start at the
  /// top, and not on a rationale or answer toggle.
  static String _screenIdOf(SolutionReaderContent content) =>
      content.onBriefing ? 'briefing' : content.levelLabel;

  String get _screenId => _screenIdOf(widget.params.content);

  @override
  void initState() {
    super.initState();
    // Arriving with quarks already earned is not an award. Whatever the first
    // frame says is simply what the student walked in carrying.
    _shownQuarkBalanceLabel = widget.params.content.quarkBalanceLabel;
    _flight.addStatusListener((status) {
      if (status == AnimationStatus.completed) _landQuarks();
    });
  }

  /// Commits the number. This is the guaranteed path: every route that starts a
  /// pellet ends here, including the one where no pellet ever flew.
  ///
  /// Never keep the total inside the animation. The pellet is decoration — it
  /// does not run under reduced motion, and another award can cut it short —
  /// but the counter must arrive at the truth either way.
  void _landQuarks() {
    if (!mounted) return;
    _flight.stop();
    final label =
        _pendingQuarkBalanceLabel ?? widget.params.content.quarkBalanceLabel;
    setState(() {
      _flyingRewardLabel = null;
      _pendingQuarkBalanceLabel = null;
      _shownQuarkBalanceLabel = label;
      _quarkLandings++;
    });
  }

  /// Sends the quarks a reveal just earned from the vault to the HUD balance.
  ///
  /// Nothing flies for a reveal that paid nothing, or to a balance that was not
  /// showing yet: the new number simply lands.
  void _awardQuarks() {
    // A second award mid-flight commits the first. It may cost the student the
    // animation, but it must never cost them the quarks.
    if (_pendingQuarkBalanceLabel != null) _landQuarks();

    final content = widget.params.content;
    _pendingQuarkBalanceLabel = content.quarkBalanceLabel;

    if (content.rewardLabel.isEmpty ||
        _shownQuarkBalanceLabel.isEmpty ||
        !MotionPolicy.of(context)) {
      _landQuarks();
      return;
    }

    final stage = _stageKey.currentContext?.findRenderObject();
    final vault = _vaultKey.currentContext?.findRenderObject();
    final dot = _quarkDotKey.currentContext?.findRenderObject();

    if (stage is! RenderBox ||
        vault is! RenderBox ||
        dot is! RenderBox ||
        !stage.hasSize ||
        !vault.hasSize ||
        !dot.hasSize) {
      _landQuarks();
      return;
    }

    Offset centreIn(RenderBox box) =>
        stage.globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));

    setState(() {
      _flyingRewardLabel = content.rewardLabel;
      _pelletFrom = centreIn(vault);
      _pelletTo = centreIn(dot);
    });
    _flight.forward(from: 0);
  }

  @override
  void didUpdateWidget(SolutionReaderTemplate oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.params.content;
    final current = widget.params.content;
    final quarksChanged = previous.rewardLabel != current.rewardLabel ||
        previous.quarkBalanceLabel != current.quarkBalanceLabel;
    if (quarksChanged) {
      // Geometry is only true once the opened vault has laid out.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _awardQuarks();
      });
    }
    final movedOn = _screenIdOf(previous) != _screenId;
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
      _ctaHandler(content)();
    } else {
      if (!content.canGoBack) return;
      widget.params.onBack();
    }
  }

  /// The button and the swipe do the same thing, so they resolve it the same
  /// way — from the action the presenter named, never by re-deriving it.
  VoidCallback _ctaHandler(SolutionReaderContent content) {
    return switch (content.ctaAction) {
      SolutionCtaAction.reveal => _requestReveal,
      SolutionCtaAction.advance => widget.params.onNext,
    };
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

    // Once the reading column has stopped growing there is width to spare, and
    // the road is better spent standing up beside the reading than lying across
    // the top of it -- a wide window is short, and height is what it has least
    // of. Below that the window *is* the column, so the bar stays.
    final asRail =
        MediaQuery.sizeOf(context).width >= AppLayout.maxContentWidth;

    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          key: _stageKey,
          children: [
            SafeArea(
              child: Column(
                children: [
                  QuestHudOrganism(
                    params: QuestHudParams(
                      topic: content.topic,
                      method: content.method,
                      // The shown balance, not the live one: while a reward is in
                      // flight the balance has not been paid yet, and a number that
                      // updates before the reward arrives makes the flight a lie.
                      quarkBalanceLabel: _shownQuarkBalanceLabel,
                      quarkKey: _quarkDotKey,
                      quarkTrigger: _quarkLandings,
                    ),
                  ),
                  if (!asRail)
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 2.h, 16.w, 0),
                      child: _trail(content, Axis.horizontal),
                    ),
                  Expanded(
                    child: asRail
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(16.w, 8.h, 0, 0),
                                child: Align(
                                  // The road hangs from the top and runs down
                                  // only as far as it needs to. Stretched to
                                  // the full height it would leave craters
                                  // between the steps.
                                  alignment: Alignment.topCenter,
                                  widthFactor: 1,
                                  child: _trail(content, Axis.vertical),
                                ),
                              ),
                              Expanded(child: _body(content)),
                            ],
                          )
                        : _body(content),
                  ),
                  SolutionCtaBarOrganism(
                    params: SolutionCtaBarParams(
                      ctaLabel: content.ctaLabel,
                      ctaSolved: content.ctaSolved,
                      onCtaPressed: _ctaHandler(content),
                      canGoBack: content.canGoBack,
                      onBack: params.onBack,
                      showSwipeHint: !content.onBriefing,
                      swipeHintUsed: content.hasMoved,
                    ),
                  ),
                ],
              ),
            ),
            if (_flyingRewardLabel != null) _buildPellet(),
          ],
        ),
      ),
    );
  }

  /// What is being read right now: the plan on its own, or a step with the
  /// vault sitting under it.
  Widget _trail(SolutionReaderContent content, Axis axis) {
    return SolutionTrailOrganism(
      nodes: content.trail,
      onNodeTap: widget.params.onTravelTo,
      axis: axis,
    );
  }

  Widget _body(SolutionReaderContent content) {
    return GestureDetector(
      // Horizontal only: reading up and down must never cost the student their
      // place.
      onHorizontalDragEnd: (d) => _swipe(d, content),
      child: SingleChildScrollView(
        key: const Key('solution_scroll'),
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _screenChildren(content),
        ),
      ),
    );
  }

  List<Widget> _screenChildren(SolutionReaderContent content) {
    if (content.onBriefing) {
      return [_popped(_briefing(content))];
    }
    return [_popped(_step(content)), _vault(content)];
  }

  /// Keyed by screen so the card pops and its contents rise again on every
  /// move, rather than the words silently changing inside a frame that never
  /// moved.
  Widget _popped(Widget child) =>
      CardPopAtom(key: ValueKey<String>(_screenId), child: child);

  Widget _briefing(SolutionReaderContent content) {
    return SolutionBriefingOrganism(
      params: SolutionBriefingParams(
        title: content.briefingTitle,
        body: content.briefingBody,
        note: content.note,
        onEnlargeVisual: widget.params.onEnlargeVisual,
        imageProviderBuilder: widget.params.imageProviderBuilder,
      ),
    );
  }

  Widget _step(SolutionReaderContent content) {
    return SolutionStepOrganism(
      params: SolutionStepParams(
        levelLabel: content.levelLabel,
        stepTitle: content.stepTitle,
        body: content.body,
        rationale: content.rationale,
        hasRationale: content.hasRationale,
        rationaleVisible: content.rationaleVisible,
        rationaleToggleLabel: content.rationaleToggleLabel,
        onToggleRationale: widget.params.onToggleRationale,
        onEnlargeVisual: widget.params.onEnlargeVisual,
        imageProviderBuilder: widget.params.imageProviderBuilder,
      ),
    );
  }

  Widget _vault(SolutionReaderContent content) {
    return SolutionVaultOrganism(
      key: _vaultKey,
      revealed: content.answerRevealed,
      unlockable: content.isLastStep,
      lockedLabel: content.vaultLockedLabel,
      solvedLabel: content.vaultSolvedLabel,
      rewardLabel: content.rewardLabel,
      checkTitle: content.checkTitle,
      checkBody: content.checkBody,
      answerBody: content.answerBody,
      resisting: _resisting,
      onReveal: _requestReveal,
      onEnlargeVisual: widget.params.onEnlargeVisual,
      imageProviderBuilder: widget.params.imageProviderBuilder,
    );
  }

  /// The pellet's arc: out past the midpoint, rising, then shrinking into the
  /// balance. A straight fade would say the quarks evaporated; the arc says
  /// they were carried somewhere and put away.
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
        key: const Key('quark_reward'),
        child: QuarkRewardAtom(label: _flyingRewardLabel ?? ''),
      ),
    );
  }
}
