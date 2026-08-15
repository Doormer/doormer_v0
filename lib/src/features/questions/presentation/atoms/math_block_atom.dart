import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One LaTeX expression from the payload. Scrolls horizontally when it is
/// wider than the card, and announces that it does — the longest expression in
/// a real payload measures 1.9x the card width.
class MathBlockAtom extends StatefulWidget {
  final String latex;
  final String semanticsLabel;

  const MathBlockAtom({
    super.key,
    required this.latex,
    required this.semanticsLabel,
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
    final cs = context.colorScheme;

    return Semantics(
      label: widget.semanticsLabel,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 8.h),
        padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10.r),
          border: Border(left: BorderSide(color: cs.tertiary, width: 3.w)),
        ),
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
                      fontSize: 14.sp,
                      color: cs.onSurface,
                    ),
                    onErrorFallback: (error) => Text(
                      widget.latex,
                      style: TextStyle(fontSize: 13.sp, color: cs.onSurface),
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
                          cs.surfaceContainerHighest.withValues(alpha: 0),
                          cs.surfaceContainerHighest,
                        ],
                      ),
                    ),
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.chevron_right,
                      size: 16.sp,
                      color: cs.onSurfaceVariant,
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
