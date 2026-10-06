import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/atoms/photo_thumbnail_atom.dart';
import 'package:doormer/src/features/questions/presentation/molecules/saved_question_row_molecule.dart';
import 'package:doormer/src/features/questions/presentation/params/saved_questions_body_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The Saved rows, newest first. Scrolling near the end asks for the next page.
/// While it loads, a spinner closes the list; if it fails, a Try again row
/// does, and scrolling asks for nothing until it is tapped.
class SavedQuestionListOrganism extends StatelessWidget {
  /// How close to the end of the list, in logical pixels, the next page is
  /// asked for: about six rows ahead, so it usually arrives before it is
  /// needed.
  static const double loadMoreDistance = 600;

  final SavedQuestionListParams params;
  final PhotoImageProviderBuilder imageProviderBuilder;

  const SavedQuestionListOrganism({
    super.key,
    required this.params,
    this.imageProviderBuilder = networkPhotoImageProvider,
  });

  bool get _wantsMore =>
      params.hasMore && !params.isLoadingMore && !params.loadMoreFailed;

  bool get _hasEndRow => params.isLoadingMore || params.loadMoreFailed;

  bool _onScroll(ScrollNotification notification) {
    if (_wantsMore && notification.metrics.extentAfter < loadMoreDistance) {
      params.onLoadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final rows = params.rows;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: ListView.separated(
        key: const Key('saved_question_list'),
        padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 16.h),
        itemCount: rows.length + (_hasEndRow ? 1 : 0),
        separatorBuilder: (_, __) => SizedBox(height: 4.h),
        itemBuilder: (context, index) {
          if (index < rows.length) {
            return SavedQuestionRowMolecule(
              params: rows[index],
              imageProviderBuilder: imageProviderBuilder,
            );
          }
          return params.loadMoreFailed
              ? _TryAgainRow(onRetry: params.onRetryLoadMore)
              : const _LoadingMoreRow();
        },
      ),
    );
  }
}

class _LoadingMoreRow extends StatelessWidget {
  const _LoadingMoreRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(
        child: SizedBox(
          width: 22.w,
          height: 22.w,
          child: CircularProgressIndicator(
            key: const Key('saved_question_list_loading_more'),
            strokeWidth: 2.5.w,
            color: QuestPalette.violet,
          ),
        ),
      ),
    );
  }
}

class _TryAgainRow extends StatelessWidget {
  final VoidCallback onRetry;

  const _TryAgainRow({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Center(
        child: TextButton(
          key: const Key('saved_question_list_retry'),
          onPressed: onRetry,
          child: Text(
            'Try again',
            style: TextStyle(fontSize: 13.sp, color: QuestPalette.cream),
          ),
        ),
      ),
    );
  }
}
