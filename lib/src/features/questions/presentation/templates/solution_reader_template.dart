import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/features/questions/presentation/molecules/solution_trail_molecule.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_briefing_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_check_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_step_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_vault_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_briefing_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_reader_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_step_params.dart';
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
  final ScrollController _scrollController = ScrollController();

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
    }
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
    final cs = context.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 10.h),
              child: SolutionTrailMolecule(nodes: content.trail),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const Key('solution_scroll'),
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
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
                              onToggleRationale: params.onToggleRationale,
                              onEnlargeVisual: params.onEnlargeVisual,
                              imageProviderBuilder: params.imageProviderBuilder,
                            ),
                          ),
                          SolutionVaultOrganism(
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
    );
  }
}

/// Opaque, with a 26px fade above it. At 92% opacity content showed through
/// and text was cut mid-glyph at the boundary, which reads as broken rather
/// than scrollable.
class _CtaBar extends StatelessWidget {
  final SolutionReaderParams params;

  const _CtaBar({required this.params});

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final content = params.content;

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
                colors: [cs.surface.withValues(alpha: 0), cs.surface],
              ),
            ),
          ),
        ),
        Container(
          color: cs.surface,
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
          child: Row(
            children: [
              TextButton.icon(
                key: const Key('solution_back'),
                onPressed: content.canGoBack ? params.onBack : null,
                icon: Icon(Icons.chevron_left, size: 18.sp),
                label: const Text('Back'),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: FilledButton(
                  key: const Key('solution_cta'),
                  onPressed: content.ctaEnabled
                      ? (content.isLastStep
                          ? params.onRevealAnswer
                          : params.onNext)
                      : null,
                  child: Text(content.ctaLabel),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
