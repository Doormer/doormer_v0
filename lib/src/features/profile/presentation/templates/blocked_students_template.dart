import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/tile_grid_atom.dart';
import 'package:doormer/src/shared/design/atomic/molecules/error_with_retry_molecule.dart';
import 'package:doormer/src/shared/design/atomic/molecules/page_heading_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../molecules/blocked_student_row_molecule.dart';
import '../params/blocked_students_body_params.dart';

/// The Blocked students page: its heading with a way back to Profile, then
/// whatever [body] holds. It sits inside the Profile tab, above the nav bar.
/// On a wide screen, the students sit two to a line, as tiles, each with its
/// Unblock.
class BlockedStudentsTemplate extends StatelessWidget {
  /// From this width up, the screen is wide.
  ///
  /// Measured against the content column, not the window: see
  /// `CollectionTemplate.railBreakpoint`. The column is at most 760 wide.
  static const double wideBreakpoint = 600;

  final BlockedStudentsBodyParams body;
  final VoidCallback onBack;

  const BlockedStudentsTemplate({
    super.key,
    required this.body,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeadingMolecule(title: 'Blocked students', onBack: onBack),
            Expanded(child: _content(isWide: isWide)),
          ],
        ),
      ),
    );
  }

  Widget _content({required bool isWide}) {
    return switch (body) {
      BlockedStudentsLoadingParams() => const Center(
          child: CircularProgressIndicator(color: QuestPalette.violet),
        ),
      BlockedStudentsErrorParams(:final message, :final onRetry) => Center(
          child: ErrorWithRetryMolecule(
            message: message,
            onRetry: onRetry,
            retryLabel: 'Try again',
          ),
        ),
      BlockedStudentListParams(:final rows) when rows.isEmpty => Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Text(
              "You haven't blocked anyone.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: QuestPalette.muted),
            ),
          ),
        ),
      BlockedStudentListParams(:final rows) => ListView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          children: [
            if (isWide)
              TileGridAtom(
                columns: 2,
                children: [
                  for (final row in rows)
                    BlockedStudentRowMolecule(params: row),
                ],
              )
            else
              for (final row in rows) BlockedStudentRowMolecule(params: row),
          ],
        ),
    };
  }
}
