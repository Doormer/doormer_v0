import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/params/saved_list_switch_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Mine and Shared with me, side by side, with the list shown lit. It keeps
/// its own width, on the left under the heading, on any screen.
class SavedListSwitchMolecule extends StatelessWidget {
  final SavedListSwitchParams params;

  const SavedListSwitchMolecule({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ListChoice(
          key: const Key('saved_list_mine'),
          label: 'Mine',
          isSelected: params.selected == SavedList.mine,
          onTap: () => params.onSelect(SavedList.mine),
        ),
        SizedBox(width: 8.w),
        _ListChoice(
          key: const Key('saved_list_shared'),
          label: 'Shared with me',
          isSelected: params.selected == SavedList.sharedWithMe,
          onTap: () => params.onSelect(SavedList.sharedWithMe),
        ),
      ],
    );
  }
}

class _ListChoice extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ListChoice({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18.r);
    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? QuestPalette.violet : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: isSelected
                ? QuestPalette.violet
                : Colors.white.withValues(alpha: 0.24),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: kDisplayFont,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? QuestPalette.cream : QuestPalette.dim,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
