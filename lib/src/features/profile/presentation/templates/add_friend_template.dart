import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/molecules/error_with_retry_molecule.dart';
import 'package:doormer/src/shared/design/atomic/molecules/page_heading_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../molecules/find_friend_molecule.dart';
import '../organisms/found_student_organism.dart';
import '../organisms/friend_code_organism.dart';
import '../params/add_friend_body_params.dart';

/// Add a friend: the student's own code, then the box to find a friend's
/// code and what it found. It sits inside the Profile tab, above the nav bar.
class AddFriendTemplate extends StatelessWidget {
  final AddFriendBodyParams body;
  final VoidCallback onBack;

  const AddFriendTemplate({
    super.key,
    required this.body,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeadingMolecule(title: 'Add a friend', onBack: onBack),
            Expanded(child: _content()),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    return switch (body) {
      AddFriendLoadingParams() => const Center(
          child: CircularProgressIndicator(color: QuestPalette.violet),
        ),
      AddFriendMessageParams(:final message, :final onRetry) => Center(
          child: onRetry == null
              ? Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.sp, color: QuestPalette.body),
                  ),
                )
              : ErrorWithRetryMolecule(
                  message: message,
                  onRetry: onRetry,
                  retryLabel: 'Try again',
                ),
        ),
      AddFriendFormParams form => ListView(
          padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
          children: [
            FriendCodeOrganism(params: form.yourCode),
            SizedBox(height: 24.h),
            FindFriendMolecule(
              initialCode: form.initialCode,
              isFinding: form.isFinding,
              onFind: form.onFind,
            ),
            SizedBox(height: 16.h),
            if (form.findMessage case final message?)
              Text(
                message,
                style: TextStyle(fontSize: 13.sp, color: QuestPalette.body),
              ),
            if (form.found case final found?)
              FoundStudentOrganism(params: found),
          ],
        ),
    };
  }
}
