import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/atoms/accent_well_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A one-line caveat about how the question's data was read.
///
/// Renders nothing when there is no caveat, so an absent note leaves no gap
/// and no orphan icon.
class NoteCaveatMolecule extends StatelessWidget {
  final String note;

  const NoteCaveatMolecule({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    if (note.isEmpty) {
      return const SizedBox.shrink();
    }

    return AccentWellAtom(
      key: const Key('solution_note'),
      accent: QuestPalette.amber,
      margin: EdgeInsets.only(top: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_rounded, size: 15.sp, color: QuestPalette.amber),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              note,
              style: TextStyle(
                fontFamily: kBodyFont,
                fontSize: 12.sp,
                height: 1.5,
                color: QuestPalette.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
