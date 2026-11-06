import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/level_icons_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// How levels work, opened from the ⓘ on Profile's level card: what counts
/// as an active day, that a level never goes down, how stars, moons and suns
/// add up, and that friends see the level. Nothing in it urges a visit.
class HowLevelsWorkSheetOrganism extends StatelessWidget {
  final VoidCallback onClose;

  const HowLevelsWorkSheetOrganism({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final bodyStyle = TextStyle(
      fontFamily: kBodyFont,
      fontSize: 14.sp,
      height: 1.4,
      color: QuestPalette.body,
    );
    return SafeArea(
      top: false,
      // Scrolls when large text or a short screen leaves too little room.
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How levels work',
              style: TextStyle(
                fontFamily: kDisplayFont,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: QuestPalette.cream,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Open Doormer on any day and it counts as an active day, once '
              'a day.',
              style: bodyStyle,
            ),
            SizedBox(height: 10.h),
            Text(
              'Your level grows with active days and never goes down, so '
              'breaks are fine.',
              style: bodyStyle,
            ),
            SizedBox(height: 10.h),
            Text('4 stars make a moon. 4 moons make a sun.', style: bodyStyle),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 20.w,
              runSpacing: 8.h,
              children: [
                _makes(_icons(stars: 4), _icons(moons: 1)),
                _makes(_icons(moons: 4), _icons(suns: 1)),
              ],
            ),
            SizedBox(height: 10.h),
            Text('Friends you add see your level.', style: bodyStyle),
            SizedBox(height: 20.h),
            AppButtonAtom(
              label: 'Got it',
              variant: AppButtonVariant.filled,
              expand: true,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }

  /// Icons with no label: the line above says what they show.
  LevelIconsAtom _icons({int suns = 0, int moons = 0, int stars = 0}) =>
      LevelIconsAtom(
        suns: suns,
        moons: moons,
        stars: stars,
        size: 18.w,
        semanticLabel: null,
      );

  /// [parts] making [whole], such as four stars, an arrow, and a moon.
  Widget _makes(LevelIconsAtom parts, LevelIconsAtom whole) => ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            parts,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16.w,
                color: QuestPalette.muted,
              ),
            ),
            whole,
          ],
        ),
      );
}
