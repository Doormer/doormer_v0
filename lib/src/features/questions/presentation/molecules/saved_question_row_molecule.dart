import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/atoms/photo_thumbnail_atom.dart';
import 'package:doormer/src/features/questions/presentation/params/saved_question_row_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One question in the Saved list: the student's photo on the left, then the
/// topic, when it was asked, and the question itself. Tapping the photo shows
/// the full photo; tapping anywhere else opens the solution.
class SavedQuestionRowMolecule extends StatelessWidget {
  final SavedQuestionRowParams params;
  final PhotoImageProviderBuilder imageProviderBuilder;

  const SavedQuestionRowMolecule({
    super.key,
    required this.params,
    this.imageProviderBuilder = networkPhotoImageProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: const Key('saved_question_row'),
        onTap: params.onOpen,
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: 'Show the full photo',
                child: InkWell(
                  key: const Key('saved_question_photo'),
                  onTap: params.onEnlargePhoto,
                  borderRadius: BorderRadius.circular(10.r),
                  child: PhotoThumbnailAtom(
                    url: params.thumbnailUrl,
                    size: 80.w,
                    imageProviderBuilder: imageProviderBuilder,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            params.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: QuestPalette.cream,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          params.askedLabel,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: QuestPalette.muted,
                          ),
                        ),
                      ],
                    ),
                    if (params.detail.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        params.detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: QuestPalette.body,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
