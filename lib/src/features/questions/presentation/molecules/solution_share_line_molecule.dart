import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_share_line_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The line above the reader's buttons about sharing the question: for the
/// student's own question, Share, and once it is shared, who with and Stop
/// sharing.
///
/// The buttons follow the words, so on a wide screen none sits at the far
/// end of the bar, away from what it acts on.
class SolutionShareLineMolecule extends StatelessWidget {
  final SolutionShareLineParams params;

  const SolutionShareLineMolecule({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    return switch (params) {
      OwnQuestionShareLineParams own => _ownQuestion(own),
    };
  }

  Widget _ownQuestion(OwnQuestionShareLineParams own) {
    final share = _LineButton(
      key: const Key('share_open'),
      label: 'Share',
      icon: Icons.share_rounded,
      onPressed: own.onShare,
    );
    if (own.sharedWithLabel.isEmpty) {
      return Align(alignment: Alignment.centerLeft, child: share);
    }
    return Row(
      children: [
        Icon(Icons.group_rounded, size: 16.w, color: QuestPalette.muted),
        SizedBox(width: 6.w),
        Flexible(child: _Words(own.sharedWithLabel)),
        SizedBox(width: 4.w),
        share,
        _LineButton(
          key: const Key('share_stop'),
          label: 'Stop sharing',
          isRisky: true,
          isBusy: own.isStopping,
          onPressed: own.onStopSharing,
        ),
      ],
    );
  }
}

class _Words extends StatelessWidget {
  final String text;

  const _Words(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 12.sp, color: QuestPalette.body),
    );
  }
}

/// A quiet button on the line. A risky one, which can't be undone by a tap,
/// is red.
class _LineButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isRisky;
  final bool isBusy;
  final VoidCallback onPressed;

  const _LineButton({
    super.key,
    required this.label,
    this.icon,
    this.isRisky = false,
    this.isBusy = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = isRisky ? context.colorScheme.error : QuestPalette.cream;
    final style = TextButton.styleFrom(
      foregroundColor: color,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      minimumSize: Size(0, 40.h),
    );
    if (isBusy) {
      return TextButton(
        style: style,
        onPressed: null,
        child: SizedBox.square(
          dimension: 16.w,
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
      );
    }
    final text = Text(
      label,
      style: TextStyle(
        fontFamily: kDisplayFont,
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
    final glyph = icon;
    return glyph == null
        ? TextButton(style: style, onPressed: onPressed, child: text)
        : TextButton.icon(
            style: style,
            onPressed: onPressed,
            icon: Icon(glyph, size: 16.w, color: color),
            label: text,
          );
  }
}
