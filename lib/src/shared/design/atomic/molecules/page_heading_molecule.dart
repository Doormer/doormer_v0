import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A page's heading: a back arrow first when the page has somewhere to go
/// back to, then [leading], such as a picture, then the title.
class PageHeadingMolecule extends StatelessWidget {
  final String title;

  /// Null on a page with nowhere to go back to.
  final VoidCallback? onBack;

  final Widget? leading;

  const PageHeadingMolecule({
    super.key,
    required this.title,
    this.onBack,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final onBack = this.onBack;
    final leading = this.leading;
    return Padding(
      padding:
          EdgeInsets.fromLTRB(onBack == null ? 20.w : 8.w, 20.h, 20.w, 12.h),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              key: const Key('page_back'),
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              color: QuestPalette.cream,
              tooltip: 'Back',
            ),
          if (leading != null) ...[leading, SizedBox(width: 10.w)],
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: kDisplayFont,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w600,
                  color: QuestPalette.cream,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
