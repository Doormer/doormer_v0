import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/glow_badge_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Asks the student to confirm an action, such as Reset code: a badge with
/// [icon], the [title] and [message], then Cancel and the confirm button.
///
/// A risky action, one that can't be undone, has its badge and confirm
/// button in the theme's error red, so it never looks like Cancel. Pages
/// show it with [showConfirmDialog].
class ConfirmDialogMolecule extends StatelessWidget {
  /// The widest the dialog grows.
  static const double _maxWidth = 400;

  /// A dialog narrower than this stacks its buttons, confirm on top.
  static const double _stackedBelowWidth = 260;

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;

  /// The action can't be undone.
  final bool isRisky;

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConfirmDialogMolecule({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    required this.icon,
    this.isRisky = true,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final accent = isRisky ? cs.error : QuestPalette.violet;
    final cancel = AppButtonAtom(
      label: cancelLabel,
      variant: AppButtonVariant.outlined,
      autofocus: true,
      onPressed: onCancel,
    );
    final confirm = AppButtonAtom(
      label: confirmLabel,
      variant: isRisky ? AppButtonVariant.danger : AppButtonVariant.filled,
      onPressed: onConfirm,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: title,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: LayoutBuilder(
            builder: (context, constraints) => Container(
              padding: EdgeInsets.all(22.w),
              decoration: BoxDecoration(
                color: QuestPalette.card,
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlowBadgeAtom(
                    icon: icon,
                    color: accent,
                    size: 44.w,
                    iconSize: 22.w,
                    glowRadius: 16.r,
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kDisplayFont,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: QuestPalette.cream,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kBodyFont,
                      fontSize: 14.sp,
                      height: 1.4,
                      color: QuestPalette.body,
                    ),
                  ),
                  SizedBox(height: 22.h),
                  if (constraints.maxWidth < _stackedBelowWidth)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [confirm, SizedBox(height: 10.h), cancel],
                    )
                  else
                    Row(
                      children: [
                        Expanded(child: cancel),
                        SizedBox(width: 10.w),
                        Expanded(child: confirm),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a [ConfirmDialogMolecule] over the whole screen, nav bar included,
/// and answers true only when the student confirms. Cancel, Escape and a tap
/// outside the dialog all answer false.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  required IconData icon,
  bool isRisky = true,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (dialogContext) => ConfirmDialogMolecule(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      icon: icon,
      isRisky: isRisky,
      onConfirm: () => Navigator.of(dialogContext).pop(true),
      onCancel: () => Navigator.of(dialogContext).pop(false),
    ),
  );
  return confirmed ?? false;
}
