import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/atoms/accent_well_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One LaTeX expression from the payload. Scrolls horizontally when it is
/// wider than the card, and announces that it does — the longest expression in
/// a real payload measures 1.9x the card width.
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

class _MathBlockAtomState extends State<MathBlockAtom> {
  final ScrollController _controller = ScrollController();
  bool _overflows = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncOverflow());
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const well = AccentWellAtom.wellColor;
    final inkColor =
        widget.emphasised ? QuestPalette.mint : QuestPalette.cream;
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
              child: SingleChildScrollView(
                key: const Key('math_block_scroll'),
                controller: _controller,
                scrollDirection: Axis.horizontal,
                child: ExcludeSemantics(
                  child: Math.tex(
                    widget.latex,
                    textStyle: TextStyle(
                      fontSize: size,
                      fontWeight:
                          widget.emphasised ? FontWeight.w700 : null,
                      color: inkColor,
                    ),
                    onErrorFallback: (error) => Text(
                      widget.latex,
                      style: TextStyle(fontSize: size, color: inkColor),
                    ),
                  ),
                ),
              ),
            ),
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
