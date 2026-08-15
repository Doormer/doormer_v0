import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/features/questions/presentation/molecules/solution_trail_molecule.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_step_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_vault_organism.dart';
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
class SolutionReaderTemplate extends StatelessWidget {
  final SolutionReaderParams params;

  const SolutionReaderTemplate({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
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
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SolutionStepOrganism(
                      params: SolutionStepParams(
                        levelLabel: content.levelLabel,
                        stepTitle: content.stepTitle,
                        body: content.body,
                        rationale: content.rationale,
                        hasRationale: content.hasRationale,
                        rationaleVisible: content.rationaleVisible,
                        rationaleToggleLabel: content.rationaleToggleLabel,
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
