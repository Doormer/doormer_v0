import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/molecules/solution_trail_molecule.dart';
import 'package:doormer/src/features/questions/presentation/organisms/quest_hud_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_briefing_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_check_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_step_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_vault_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/quest_hud_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_briefing_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_reader_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_step_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/quest_backdrop.dart';
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

class _SolutionReaderTemplateState extends State<SolutionReaderTemplate> {
  /// Headroom inside the scroll view for the XP sticker, which is positioned
  /// 9px above the card's top edge and so sits outside it. With a zero top
  /// padding the viewport clipped the sticker in half — the tag read as a torn
  /// mint strip rather than a reward.
  static const double _stickerHeadroom = 14;

  final ScrollController _scrollController = ScrollController();

  /// Locates the vault so revealing the answer can bring it into view.
  final GlobalKey _vaultKey = GlobalKey();

  /// Identifies which screen is showing. The level label already encodes the
  /// step, so this changes on exactly the transitions that should start at the
  /// top, and not on a rationale or answer toggle.
  String get _screenId {
    final content = widget.params.content;
    return content.onBriefing ? 'briefing' : content.levelLabel;
  }

  @override
  void didUpdateWidget(SolutionReaderTemplate oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.params.content;
    final previousId =
        previous.onBriefing ? 'briefing' : previous.levelLabel;
    if (previousId != _screenId && _scrollController.hasClients) {
      _scrollController.jumpTo(0);
      return;
    }

    // The answer is the payoff of the whole page, and it sits below the fold:
    // revealing it changed only the trail marker and the button, so the tap
    // read as having done nothing. Bring the vault to the student instead.
    final revealedNow = !previous.answerRevealed &&
        widget.params.content.answerRevealed;
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

  @override
  void dispose() {
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
        child: SafeArea(
          child: Column(
          children: [
            QuestHudOrganism(
              params: QuestHudParams(
                topic: content.topic,
                questionTitle: content.questionTitle,
                xpLabel: content.xpLabel,
                streakLabel: content.streakLabel,
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
                          SolutionBriefingOrganism(
                            params: SolutionBriefingParams(
                              title: content.briefingTitle,
                              body: content.briefingBody,
                              note: content.note,
                              onEnlargeVisual: params.onEnlargeVisual,
                              imageProviderBuilder: params.imageProviderBuilder,
                            ),
                          ),
                        ]
                      : [
                          SolutionStepOrganism(
                            params: SolutionStepParams(
                              levelLabel: content.levelLabel,
                              stepTitle: content.stepTitle,
                              body: content.body,
                              rationale: content.rationale,
                              hasRationale: content.hasRationale,
                              rationaleVisible: content.rationaleVisible,
                              rationaleToggleLabel:
                                  content.rationaleToggleLabel,
                              xpLabel: content.stepXpLabel,
                              onToggleRationale: params.onToggleRationale,
                              onEnlargeVisual: params.onEnlargeVisual,
                              imageProviderBuilder: params.imageProviderBuilder,
                            ),
                          ),
                          SolutionVaultOrganism(
                            key: _vaultKey,
                            revealed: content.answerRevealed,
                            unlockable: content.isLastStep,
                            lockedLabel: content.vaultLockedLabel,
                            answerBody: content.answerBody,
                            onReveal: params.onRevealAnswer,
                            onEnlargeVisual: params.onEnlargeVisual,
                            imageProviderBuilder: params.imageProviderBuilder,
                          ),
                          SolutionCheckOrganism(
                            title: content.checkTitle,
                            body: content.checkBody,
                            onEnlargeVisual: params.onEnlargeVisual,
                            imageProviderBuilder: params.imageProviderBuilder,
                          ),
                        ],
                ),
              ),
            ),
            _CtaBar(params: params),
          ],
          ),
        ),
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

  const _CtaBar({required this.params});

  @override
  Widget build(BuildContext context) {
    final content = params.content;
    final solved = !content.ctaEnabled;
    final accent = solved ? QuestPalette.mint : QuestPalette.violet;
    final edge = solved ? const Color(0xFF00A874) : const Color(0xFF4A2FD1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
                      ? (content.isLastStep
                          ? params.onRevealAnswer
                          : params.onNext)
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
