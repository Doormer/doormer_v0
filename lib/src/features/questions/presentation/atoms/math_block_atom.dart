import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/atoms/accent_well_atom.dart';
import 'package:doormer/src/features/questions/presentation/atoms/math_flow_atom.dart';
import 'package:doormer/src/features/questions/utils/math_clauses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One LaTeX expression from the payload.
///
/// Long working wraps at its relations, the way a textbook carries a chain of
/// equalities onto the next line, so the student reads it rather than dragging
/// it sideways. Only an expression with nothing safe to break — no relation
/// anywhere at the top level — still scrolls, and it says so when it does.
class MathBlockAtom extends StatefulWidget {
  final String latex;
  final String semanticsLabel;

  /// The final answer is set large and mint so it lands as the thing the whole
  /// page was walking towards, not as one more equation.
  final bool emphasised;

  const MathBlockAtom({
    super.key,
    required this.latex,
    required this.semanticsLabel,
    this.emphasised = false,
  });

  @override
  State<MathBlockAtom> createState() => _MathBlockAtomState();
}

class _MathBlockAtomState extends State<MathBlockAtom>
    with SingleTickerProviderStateMixin {
  final ScrollController _controller = ScrollController();
  bool _overflows = false;

  late final AnimationController _sheen;

  @override
  void initState() {
    super.initState();
    // 300ms of the run is the wait, so the sweep lands after the card has
    // arrived rather than racing it.
    _sheen = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncOverflow();
      if (mounted && MotionPolicy.of(context)) _sheen.forward();
    });
  }

  @override
  void didUpdateWidget(covariant MathBlockAtom oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latex != widget.latex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncOverflow());
    }
  }

  void _syncOverflow() {
    if (!mounted || !_controller.hasClients) return;
    final overflows = _controller.position.maxScrollExtent > 2;
    if (overflows != _overflows) {
      setState(() => _overflows = overflows);
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// A band of light passing over the expression once, the way a card catches
  /// the light as it is dealt. It runs a single time: a permanent shimmer
  /// would compete with the maths for the student's attention, and the maths
  /// must win.
  Widget _sweep(Color accent) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _sheen,
        builder: (context, _) {
          final v = _sheen.value;
          final t = ((v * 1400 - 300) / 1100).clamp(0.0, 1.0);
          if (t == 0 || t == 1) return const SizedBox.shrink();
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Transform.translate(
                offset: Offset(
                  (-1 + 2.2 * Curves.easeInOut.transform(t)) * width,
                  0,
                ),
                child: DecoratedBox(
                  key: const Key('math_block_sheen'),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: 0),
                        accent.withValues(alpha: 0.2),
                        accent.withValues(alpha: 0),
                      ],
                      stops: const [0.38, 0.5, 0.62],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// The expression, broken at its relations and flowed onto as many lines as
  /// the card needs. Clauses that fit together stay together, so a short
  /// expression looks exactly as it did before it could wrap.
  Widget _expression(double fontSize, Color inkColor, double wrapWidth) {
    final clauses = mathClauses(widget.latex);
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: widget.emphasised ? FontWeight.w700 : null,
      color: inkColor,
    );

    return MathFlowAtom(
      key: const Key('math_block_flow'),
      wrapWidth: wrapWidth,
      indent: fontSize * 1.5,
      runSpacing: fontSize * 0.5,
      gaps: [for (final clause in clauses) clause.gapEm * fontSize],
      children: [
        for (final clause in clauses)
          Math.tex(
            clause.latex,
            textStyle: style,
            onErrorFallback: (error) => Text(
              clause.latex,
              style: TextStyle(fontSize: fontSize, color: inkColor),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const well = AccentWellAtom.wellColor;
    final inkColor = widget.emphasised ? QuestPalette.mint : QuestPalette.cream;
    final size = widget.emphasised ? 26.sp : 14.sp;

    return Semantics(
      label: widget.semanticsLabel,
      child: AccentWellAtom(
        accent: inkColor,
        margin: EdgeInsets.symmetric(vertical: 8.h),
        child: Stack(
          children: [
            NotificationListener<ScrollMetricsNotification>(
              onNotification: (_) {
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _syncOverflow());
                return false;
              },
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  key: const Key('math_block_scroll'),
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  child: ExcludeSemantics(
                    child: _expression(size, inkColor, constraints.maxWidth),
                  ),
                ),
              ),
            ),
            Positioned.fill(child: _sweep(inkColor)),
            if (_overflows)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  key: const Key('math_block_overflow_hint'),
                  child: Container(
                    width: 28.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          well.withValues(alpha: 0),
                          well,
                        ],
                      ),
                    ),
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.chevron_right,
                      size: 16.sp,
                      color: inkColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
