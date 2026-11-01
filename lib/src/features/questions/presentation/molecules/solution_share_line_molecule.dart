import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_share_line_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/card_picture_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The line above the reader's buttons about sharing the question: for the
/// student's own question, Share, and once it is shared, who with and Stop
/// sharing; for a question a friend shared, who shared it, Remove and Report.
///
/// The buttons follow the words, so on a wide screen none sits at the far
/// end of the bar, away from what it acts on. When the words and the buttons
/// don't fit on one row, the words take their own line, in full, and the
/// buttons go together on the next.
class SolutionShareLineMolecule extends StatelessWidget {
  final SolutionShareLineParams params;

  const SolutionShareLineMolecule({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    return switch (params) {
      OwnQuestionShareLineParams own => _ownQuestion(own),
      FriendQuestionShareLineParams friend => _friendQuestion(friend),
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
    return _WordsThenButtons(
      lead: Icon(Icons.group_rounded, size: 16.w, color: QuestPalette.muted),
      leadGap: 6.w,
      words: own.sharedWithLabel,
      buttons: [
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

  Widget _friendQuestion(FriendQuestionShareLineParams friend) {
    return _WordsThenButtons(
      lead: CardPictureAtom(
        name: friend.nickname,
        artUrl: friend.artUrl,
        size: 22.w,
      ),
      leadGap: 8.w,
      words: friend.sharedByLabel,
      buttons: [
        _LineButton(
          key: const Key('shared_question_remove'),
          label: 'Remove',
          isRisky: true,
          isBusy: friend.isRemoving,
          onPressed: friend.onRemove,
        ),
        _LineButton(
          key: const Key('shared_question_report'),
          label: 'Report',
          icon: Icons.flag_outlined,
          onPressed: friend.onReport,
        ),
      ],
    );
  }
}

/// The words, after their icon or picture, then the buttons. They share a
/// row when it has room, the buttons right after the words. When it hasn't,
/// the words take their own line, wrapping if they must, and the buttons stay
/// together on the next, from the left.
class _WordsThenButtons extends StatelessWidget {
  final Widget lead;
  final double leadGap;
  final String words;
  final List<Widget> buttons;

  const _WordsThenButtons({
    required this.lead,
    required this.leadGap,
    required this.words,
    required this.buttons,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 4.w,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              lead,
              SizedBox(width: leadGap),
              Flexible(child: _Words(words)),
            ],
          ),
          Row(mainAxisSize: MainAxisSize.min, children: buttons),
        ],
      ),
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
